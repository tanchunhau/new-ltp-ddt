/* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License version 2 as
* published by the Free Software Foundation.
*/
#define pr_fmt(fmt) KBUILD_MODNAME ": " fmt 
#include <linux/module.h> 
#include <linux/moduleparam.h> 
#include <linux/irq.h> 
#include <linux/interrupt.h> 
#include <linux/completion.h> 
#include <linux/clk.h> 
#include <../arch/arm/plat-omap/include/plat/dmtimer.h> 
#include <linux/of.h>

struct omap_dm_timer *timer_test;
int timer_num;
int test_loop=1;
int test_period=100;
int test_type=1;
int fail_count=0; 
struct timeval t0;
struct timeval t1;
unsigned int t0_total;
unsigned int t1_total;
unsigned int t_total;
module_param(timer_num, int, S_IRUSR);
MODULE_PARM_DESC(timer_num, "Number of timer to be tested - example timer_num should be 2 for testing timer2");
module_param(test_loop, int, S_IRUSR);
MODULE_PARM_DESC(test_loop, "Number of iterations of test");
module_param(test_period, int, S_IRUSR); 
MODULE_PARM_DESC(test_period, "Number of milliseconds for timer to be triggered");
module_param(test_type, int, S_IRUSR); 
MODULE_PARM_DESC(test_type, "Type of test - 1 is for request/release timers, 2 is for request/validate/release timers");

DECLARE_COMPLETION(dmtimer_check);

static irqreturn_t dmtimer_test_isr(int irq, void *dev) {
	struct omap_dm_timer *test_timer = (struct omap_dm_timer *)dev;
	do_gettimeofday(&t1);
	t1_total = t1.tv_sec*1000000+t1.tv_usec;
	printk(KERN_ERR "Time1 inside debug2 %u\n", t1_total);
	omap_dm_timer_write_status(test_timer, OMAP_TIMER_INT_OVERFLOW);
	printk("Interrupt is triggered for irq is : %d\n", irq);
	complete_all(&dmtimer_check);
	t_total = t1_total - t0_total;
	printk(KERN_ERR "Time diff is t1 = %u\nt0 = %u\nt_diff = %u\n", t1_total, t0_total, t_total);

	if (t_total<(test_period*1000+(5*test_period*1000/100)))
		pr_info("TIMER_TEST successful\n");
	else {
		pr_err("TIMER_TEST did not measure successful latency\n");
		fail_count++;
	}

	return IRQ_HANDLED;
}

static struct irqaction dmtimer_test_irq = {
	.name = "dm timer",
	.flags = IRQF_TIMER | IRQF_IRQPOLL,
	.handler = dmtimer_test_isr,
};

static struct device_node *of_dev_timer_lookup(struct device_node *np,
                                                const char *hwmod_name) 
{
	struct device_node *np0 = NULL;
	const char *p;

	for_each_child_of_node(np, np0) {
		if (of_find_property(np0, "ti,hwmods", NULL)) {
			p = of_get_property(np0, "ti,hwmods", NULL);
                        if (!strcmp(p, hwmod_name))
				return np0;
                }
        }

	return NULL;
}

static int __init dmtimer_init(void)
{
	struct device_node *np = NULL;
	struct device_node *np0 = NULL;
	char timer_name[8];
	int i, status;
	struct clk *gt_fclk;
	unsigned int timer_irq; 
	unsigned long gt_rate, period;

	sprintf(timer_name, "timer%d", timer_num);
	pr_info("Timer is %s\n", timer_name);
	np0 = of_find_node_by_name(NULL, "ocp");
	np = of_dev_timer_lookup(np0, timer_name);

	if (np) {
		pr_info("Timer node found: timer[%d]->full_name=%s\n", timer_num, np->full_name);
 	} else {
			pr_err("NP null\n");
			return -ENODEV;
		}

	pr_info("OCP node np0 = %p\n", np0);
	pr_info("Requested timer node np = %p\n", np);

	for (i=0; i<test_loop; i++)
	{
		pr_info("TEST_LOOP is %d out of %d\n", i, test_loop);
		timer_test = omap_dm_timer_request_by_node(np);

		if (!timer_test) {
			pr_err("TIMER_TEST null\n");
			omap_dm_timer_free(timer_test);
			return -ENODEV;
		}		
		pr_info("Timer node requested: id of timer_test[%d]->id=%d\n", timer_num, timer_test->id);
		pr_info("Timer node requested: timer_test[%d]->irq=%d\n", timer_num, timer_test->irq);
		omap_dm_timer_set_source(timer_test, OMAP_TIMER_SRC_SYS_CLK);
		gt_fclk = omap_dm_timer_get_fclk(timer_test);
		gt_rate = clk_get_rate(gt_fclk);
		period = (gt_rate / 1000) * test_period; /* period ms */
		timer_irq = omap_dm_timer_get_irq(timer_test);
		dmtimer_test_irq.dev_id = (void *)timer_test;
		request_irq(timer_irq, dmtimer_test_isr, IRQF_SHARED,
				  "dmtimer-test", timer_test);
		omap_dm_timer_set_load_start(timer_test, 1, 0xffffffff - period);

		switch(test_type){
		// request/start/stop/free timers
		case 1:
			omap_dm_timer_start(timer_test);
			omap_dm_timer_set_int_enable(timer_test, OMAP_TIMER_INT_OVERFLOW);
			omap_dm_timer_stop(timer_test);
			free_irq(timer_irq, timer_test);
			omap_dm_timer_free(timer_test);
			pr_info("Freed timer\n");
			break;
		// request/set_source/set_load/start/stop/free timers
		case 2:
			init_completion(&dmtimer_check);
			do_gettimeofday(&t0);
			t0_total = t0.tv_sec*1000000+t0.tv_usec;
			printk(KERN_ERR "Time0 inside debug 1 %u\n", t0_total);
			omap_dm_timer_start(timer_test);
			omap_dm_timer_set_int_enable(timer_test, OMAP_TIMER_INT_OVERFLOW);
			status = omap_dm_timer_read_status(timer_test);

			if(status<0) {
				printk(KERN_ERR "error %d requesting dmtimer %d\n", status, timer_num);
				return status;
				}

			wait_for_completion_interruptible(&dmtimer_check);
			omap_dm_timer_stop(timer_test);
			free_irq(timer_irq, timer_test);
			omap_dm_timer_free(timer_test);
			pr_info("Freed timer\n");
			break;

		default:
			pr_err("Unsupported test type %d\n", test_type);
			return -ENODEV;
		} /* end of switch case */
            
	} /* end of loop */
      
	if (fail_count != 0)
	{
		pr_err("TIMER did not trigger within given tolerance for %d time(s)\n", fail_count);
		return -ENODEV;
	}

	return 0;
}

module_init(dmtimer_init);

MODULE_AUTHOR("Aparna Balasubramanian");
MODULE_LICENSE("GPL v2");
