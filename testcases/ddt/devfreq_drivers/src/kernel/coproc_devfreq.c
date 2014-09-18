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
 */
struct coproc_devfreq_data {
	struct devfreq_dev_profile profile;
	struct device *dev;
	struct devfreq *devfreq;
	struct devfreq_dev_status stat;
};

static struct clk *dev_clk;
static struct clk *dpll_clk;
static struct notifier_block *clk_nb;

/**
 * DOC:
 * clock-names should be defined in dts file, e.g.
 * coproc0 {
 *
 *  compatible = "ti,test-coproc";
 *  clocks = <&dpll_gpu_m2_ck>, <&dpll_gpu_ck>;
 *  clock-names = "my_fclk", "my_dpll";
 *  clock-initial-frequency = <425600000>;
 *  operating-points = <
 *    425600  1090000
 *    532000  1280000
 *  >;
 *  coproc0-voltdm = <&voltdm_gpu>;
 *  voltage-tolerance = <1>;
 *
 * };
 */
static char *dev_clk_name = "my_fclk";
static char *dpll_clk_name = "my_dpll";

static int coproc_device_getrate(struct device *dev, unsigned long *rate)
{
	if (!dev_clk)
		dev_clk = devm_clk_get(dev, dev_clk_name);
	*rate = clk_get_rate(dev_clk);
	return 0;
}

static int coproc_device_scale(struct device *dev, unsigned long rate)
{
	int err;
	pr_err("coproc_device_scale:%lu\n", rate);

	err = clk_set_rate(dpll_clk, rate);
	if (err) {
		dev_err(dev, "%s: Cannot scale dpll clock(%d).\n", __func__,
			err);
		goto scale_out;
	}

	err = clk_set_rate(dev_clk, rate);
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
	pr_err("set_target:%lu\n", *_freq);

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
	unsigned long initial_freq;
	int num_available;
	int err = 0;
	struct device *dev = &pdev->dev;
	struct device_node *np = of_node_get(dev->of_node);
	const u32 *node_ptr;

	pr_err("probe\n");

	node_ptr = of_get_property(np, "clock-initial-frequency", NULL);
	if (!node_ptr) {
		dev_err(dev,
			"%s: Could not read clock-initial-frequency from device tree \n",
			__func__);
		goto out;
	}
	initial_freq = be32_to_cpup(node_ptr);

	dpll_clk = devm_clk_get(dev, dpll_clk_name);
	if (IS_ERR(dpll_clk)) {
		dev_err(dev, "%s: Cannot get dpll clk.\n", __func__);
		goto out;
	}

	dev_clk = devm_clk_get(dev, dev_clk_name);
	if (IS_ERR(dev_clk)) {
		dev_err(dev, "%s: Cannot get func clk.\n", __func__);
		goto out;
	}

	err = clk_set_rate(dpll_clk, initial_freq);
	if (err) {
		dev_err(dev, "%s: Cannot set dpll clock rate(%d).\n", __func__,
			err);
		goto out;
	}

	err = clk_set_rate(dev_clk, initial_freq);
	if (err) {
		dev_err(dev, "%s: Cannot set func clock rate(%d).\n", __func__,
			err);
		goto out;
	}

	err = of_init_opp_table(dev);
	if (err) {
		dev_err(dev, "%s: Cannot initialize opp table(%d).\n", __func__,
			err);
		goto out;
	}

	rcu_read_lock();
	num_available = dev_pm_opp_get_opp_count(dev);
	dev_err(dev, "%s: Number of OPP availables:%d.\n", __func__,
		num_available);
	rcu_read_unlock();

	d = kzalloc(sizeof(*d), GFP_KERNEL);
	if (d == NULL) {
		dev_err(dev, "%s: Cannot allocate memory.\n", __func__);
		err = -ENOMEM;
		goto out;
	}

	d->dev = dev;
	err = coproc_device_getrate(dev, &d->profile.initial_freq);
	if (err) {
		dev_err(dev, "%s: Cannot get freq(%d).\n", __func__, err);
		goto out_mem;
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
		goto out_mem;
	}

	err = devfreq_register_opp_notifier(dev, d->devfreq);
	if (err) {
		dev_err(dev, "%s: Cannot add to devfreq opp notifier(%d).\n",
			__func__, err);
		goto out_remove;
	}

	/* Register voltage domain notifier */
	clk_nb = of_pm_voltdm_notifier_register(dev, np, dev_clk, "coproc0",
						&voltage_latency);

	if (IS_ERR(clk_nb)) {
		err = PTR_ERR(clk_nb);
		/* defer probe if regulator is not yet registered */
		if (err == -EPROBE_DEFER) {
			dev_err(dev,
				"coproc0 clock notifier not ready, retry\n");
		} else {
			dev_err(dev,
				"Failed to register coproc0 clk notifier: %d\n",
				err);
		}
		goto out_remove;
	}

	platform_set_drvdata(pdev, d);

	/* All good.. */
	goto out;

out_remove:
	devfreq_remove_device(d->devfreq);
out_mem:
	kfree(d);
out:
	dev_info(dev, "%s result=%d", __func__, err);
	return err;
}

static int coproc_devfreq_remove(struct platform_device *pdev)
{
	struct device *dev = &pdev->dev;
	struct coproc_devfreq_data *d = platform_get_drvdata(pdev);

	pr_err("remove\n");

	if (dev_clk)
		devm_clk_put(dev, dev_clk);
	if (dpll_clk)
		devm_clk_put(dev, dpll_clk);

	of_pm_voltdm_notifier_unregister(clk_nb);
	devfreq_remove_device(d->devfreq);
	kfree(d);

	dev_err(&pdev->dev, "%s Removed devfreq\n", __func__);
	return 0;
}

/**
 * coproc_devfreq_suspend() - dummy hook for suspend
 */
static int coproc_devfreq_suspend(struct device *dev)
{
	pr_err("suspend\n");
	return 0;
}

/**
 * coproc_devfreq_resume() - dummy hook for resume
 */
static int coproc_devfreq_resume(struct device *dev)
{
	pr_err("resume\n");
	return 0;
}

/* Device power management hooks */
static const struct dev_pm_ops coproc_devfreq_pm = {
	.suspend = coproc_devfreq_suspend,
	.resume = coproc_devfreq_resume,
};

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

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("OMAP Co-processor DEVFREQ Driver");
MODULE_AUTHOR("Carlos Hernandez <ceh@ti.com>, Nishanth Menon <nm@ti.com>");
