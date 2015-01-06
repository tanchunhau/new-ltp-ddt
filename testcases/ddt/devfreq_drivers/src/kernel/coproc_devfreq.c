/*
 * OMAP SoC COPROC devfreq driver
 *
 * Copyright (C) 2014 Texas Instruments Incorporated - http://www.ti.com/
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.

 * This program is distributed "as is" WITHOUT ANY WARRANTY of any
 * kind, whether express or implied; without even the implied warranty
 * of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */
#include <linux/io.h>
#include <linux/slab.h>
#include <linux/mutex.h>
#include <linux/suspend.h>
#include <linux/pm_opp.h>
#include <linux/devfreq.h>
#include <linux/of.h>
#include <linux/platform_device.h>
#include <linux/regulator/consumer.h>
#include <linux/module.h>
#include <linux/clk.h>
#include <linux/pm_voltage_domain.h>

/**
 * struct coproc_devfreq_data - Co processor private data
 * @profile:  devfreq profile specific for this device
 * @dev:  device pointer
 * @devfreq:  devfreq for this device
 * @stat: my current statistics
 * @dev_clk: my device clk
 * @dpll_clk: my dpll clk
 * @nb:	my notifier block
 */
struct coproc_devfreq_data {
	struct devfreq_dev_profile profile;
	struct device *dev;
	struct devfreq *devfreq;
	struct devfreq_dev_status stat;
	struct clk *dev_clk;
	struct clk *dpll_clk;
	struct notifier_block *clk_nb;
};

/**
 * DOC:
 * clock-names should be defined in dts file, e.g.
 * coproc {
 *
 *  compatible = "ti,test-coproc";
 *  clocks = <&dpll_gpu_m2_ck>, <&dpll_gpu_ck>;
 *  clock-names = "fclk", "dpll";
 *  clock-initial-frequency = <425600000>;
 *  operating-points = <
 *    425600  1090000
 *    532000  1280000
 *  >;
 *  coproc-voltdm = <&voltdm_gpu>;
 *  voltage-tolerance = <1>;
 *
 * };
 */
#define DEV_CLK_NAME "fclk"
#define DPLL_CLK_NAME "dpll"

static int coproc_device_getrate(struct device *dev, unsigned long *rate)
{
	struct coproc_devfreq_data *d = dev_get_drvdata(dev);

	if (!d->dev_clk)
		d->dev_clk = devm_clk_get(dev, DEV_CLK_NAME);
	*rate = clk_get_rate(d->dev_clk);
	return 0;
}

static int coproc_device_scale(struct device *dev, unsigned long rate)
{
	int err;
	struct coproc_devfreq_data *d = dev_get_drvdata(dev);

	dev_info(dev, "coproc_device_scale:%lu\n", rate);

	if (d->dpll_clk) {
		err = clk_set_rate(d->dpll_clk, rate);
		if (err) {
			dev_err(dev, "%s: Cannot scale dpll clock(%d).\n",
				__func__, err);
			goto scale_out;
		}
	}

	err = clk_set_rate(d->dev_clk, rate);
	if (err)
		dev_err(dev, "%s: Cannot scale functional clock(%d).\n",
			__func__, err);

scale_out:
	return err;
}

static int coproc_set_target(struct device *dev, unsigned long *_freq,
			     u32 flags)
{
	struct dev_pm_opp *opp;
	unsigned long rate;

	dev_info(dev, "set_target:%lu\n", *_freq);

	rcu_read_lock();
	opp = devfreq_recommended_opp(dev, _freq, flags);
	if (IS_ERR(opp)) {
		rcu_read_unlock();
		dev_err(dev, "%s: Cannot get recommended opp.\n", __func__);
		return PTR_ERR(opp);
	}
	rate = dev_pm_opp_get_freq(opp);
	rcu_read_unlock();
	return coproc_device_scale(dev, rate);
}

/**
 * coproc_exit() - done using devfreq device
 * @dev:  device
 */
static void coproc_exit(struct device *dev)
{
	struct coproc_devfreq_data *d = dev_get_drvdata(dev);

	devfreq_unregister_opp_notifier(dev, d->devfreq);
}

static int coproc_devfreq_probe(struct platform_device *pdev)
{
	struct coproc_devfreq_data *d;
	unsigned int voltage_latency;
	u32 initial_freq = 0;
	int num_available;
	int err = 0;
	struct device *dev = &pdev->dev;
	struct device_node *np = of_node_get(dev->of_node);
	bool noset_dpll_as_rate;

	dev_info(dev, "probe\n");

	of_property_read_u32(np, "clock-initial-frequency", &initial_freq);
	noset_dpll_as_rate = of_property_read_bool(np, "noset-dpll-rate");

	d = devm_kzalloc(dev, sizeof(*d), GFP_KERNEL);
	if (d == NULL) {
		dev_err(dev, "%s: Cannot allocate memory.\n", __func__);
		err = -ENOMEM;
		goto out;
	}
	platform_set_drvdata(pdev, d);

	d->dpll_clk = devm_clk_get(dev, DPLL_CLK_NAME);
	if (IS_ERR(d->dpll_clk)) {
		err = PTR_ERR(d->dpll_clk);
		dev_err(dev, "%s: Cannot get dpll clk(%d).\n", __func__, err);
		d->dpll_clk = NULL;
	}

	d->dev_clk = devm_clk_get(dev, DEV_CLK_NAME);
	if (IS_ERR(d->dev_clk)) {
		err = PTR_ERR(d->dpll_clk);
		dev_err(dev, "%s: Cannot get func clk(%d).\n", __func__, err);
		goto out;
	}

	if (initial_freq) {
		if (d->dpll_clk) {
			err = clk_set_rate(d->dpll_clk, initial_freq);
			if (err) {
				dev_err(dev, "%s: Cannot set dpll clock rate(%d).\n",
					__func__, err);
				goto out;
			}
		}

		err = clk_set_rate(d->dev_clk, initial_freq);
		if (err) {
			dev_err(dev, "%s: Cannot set func clock rate(%d).\n",
				__func__, err);
			goto out;
		}
	}

	if (noset_dpll_as_rate)
		d->dpll_clk = NULL;

	err = of_init_opp_table(dev);
	if (err) {
		dev_err(dev, "%s: Cannot initialize opp table(%d).\n", __func__,
			err);
		goto out;
	}

	rcu_read_lock();
	num_available = dev_pm_opp_get_opp_count(dev);
	dev_info(dev, "%s: Number of OPP availables:%d.\n", __func__,
		 num_available);
	rcu_read_unlock();

	d->dev = dev;
	err = coproc_device_getrate(dev, &d->profile.initial_freq);
	if (err) {
		dev_err(dev, "%s: Cannot get freq(%d).\n", __func__, err);
		goto out;
	}

	d->profile.target = coproc_set_target;
	d->profile.exit = coproc_exit;
	d->profile.polling_ms = 0;
	dev_info(dev, "%s init rate = %ld\n", __func__,
		 d->profile.initial_freq);

	d->devfreq = devfreq_add_device(dev, &d->profile, "userspace", NULL);
	if (IS_ERR(d->devfreq)) {
		err = PTR_ERR(d->devfreq);
		dev_err(dev, "%s: Cannot add to devfreq(%d).\n", __func__, err);
		goto out;
	}

	err = devfreq_register_opp_notifier(dev, d->devfreq);
	if (err) {
		dev_err(dev, "%s: Cannot add to devfreq opp notifier(%d).\n",
			__func__, err);
		goto out_remove;
	}

	/* Register voltage domain notifier */
	d->clk_nb = of_pm_voltdm_notifier_register(dev, np, d->dev_clk,
						   "coproc",
						   &voltage_latency);
	if (IS_ERR(d->clk_nb)) {
		err = PTR_ERR(d->clk_nb);
		/* defer probe if regulator is not yet registered */
		if (err == -EPROBE_DEFER) {
			dev_err(dev,
				"coproc clock notifier not ready, retry\n");
		} else {
			dev_err(dev,
				"Failed to register coproc clk notifier: %d\n",
				err);
		}
		goto out_remove;
	}

	/* All good.. */
	goto out;

out_remove:
	devfreq_remove_device(d->devfreq);
out:
	dev_info(dev, "%s result=%d", __func__, err);
	return err;
}

static int coproc_devfreq_remove(struct platform_device *pdev)
{
	struct coproc_devfreq_data *d = platform_get_drvdata(pdev);
	struct device *dev = &pdev->dev;

	dev_info(dev, "remove\n");

	of_pm_voltdm_notifier_unregister(d->clk_nb);
	devfreq_remove_device(d->devfreq);

	dev_info(dev, "%s Removed devfreq\n", __func__);
	return 0;
}

/**
 * coproc_devfreq_suspend() - dummy hook for suspend
 * @dev: device pointer
 *
 * Return: 0
 */
static int coproc_devfreq_suspend(struct device *dev)
{
	dev_info(dev, "suspend\n");
	return 0;
}

/**
 * coproc_devfreq_resume() - dummy hook for resume
 * @dev: device pointer
 *
 * Return: 0
 */
static int coproc_devfreq_resume(struct device *dev)
{
	dev_info(dev, "resume\n");
	return 0;
}

/* Device power management hooks */
static SIMPLE_DEV_PM_OPS(coproc_devfreq_pm,
			 coproc_devfreq_suspend,
			 coproc_devfreq_resume);

static struct of_device_id of_coproc_match[] = {
	{.compatible = "ti,test-coproc"},
	{},
};

MODULE_DEVICE_TABLE(of, of_coproc_match);

static struct platform_driver coproc_devfreq_driver = {
	.probe = coproc_devfreq_probe,
	.remove = coproc_devfreq_remove,
	.driver = {
		   .name = "coproc_devfreq",
		   .owner = THIS_MODULE,
		   .of_match_table = of_match_ptr(of_coproc_match),
		   .pm = &coproc_devfreq_pm,
		   },
};
module_platform_driver(coproc_devfreq_driver);

MODULE_LICENSE("GPL v2");
MODULE_DESCRIPTION("OMAP Co-processor DEVFREQ Driver");
MODULE_AUTHOR("Carlos Hernandez <ceh@ti.com>, Nishanth Menon <nm@ti.com>");
