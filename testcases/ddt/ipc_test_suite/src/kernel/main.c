#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/notifier.h>
#include <linux/err.h>
#include <linux/sched.h>

#include <linux/omap-mailbox.h>

MODULE_AUTHOR("Kevin Hilman");
MODULE_LICENSE("GPL");

/* load-time options */
int count = 16;
char *name = "mbox-ipu1";

module_param(count, int, 0);
module_param(name, charp, 0);

static int callback(struct notifier_block *this, unsigned long index,
			void *data)
{
	int ret = 0;
	mbox_msg_t msg = (mbox_msg_t) data;

	pr_info("mbox msg: 0x%x\n", msg);

	return ret;
}

struct notifier_block nb = {
	.notifier_call = callback,
};

static struct omap_mbox *mbox;

static void __exit mbox_test_cleanup(void)
{
	pr_info("%s: mbox_test_cleanup entered\n", __func__);
	if (mbox)
		omap_mbox_put(mbox, &nb);
}

static int __init mbox_test_init(void)
{
	int i, r, ret = 0;
	mbox_msg_t msg;

	pr_info("%s: mbox_test_init entered\n", __func__);
	mbox = omap_mbox_get(name, &nb);
	if (IS_ERR(mbox)) {
		pr_err("%s: omap_mbox_get() failed: 0x%p\n", __func__, mbox);
		mbox = NULL;
		ret = -EINVAL;
		goto out;
	}

	for (i = 0; i < count; i++) {
		msg = i;
		r = omap_mbox_msg_send(mbox, msg);
		if (r) {
			pr_err("%s: omap_mbox_msg_send() failed: %d\n",
			       __func__, r);
			/* Let callback empty fifo a bit, then continue: */
			set_current_state(TASK_INTERRUPTIBLE);
			schedule_timeout(HZ / 10);  /* 1/10 second */
			i--;
			continue;
		}
	}

out:
	return ret;
}

module_init(mbox_test_init);
module_exit(mbox_test_cleanup);
