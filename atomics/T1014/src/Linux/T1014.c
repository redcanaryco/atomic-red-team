/*  
 * Source from https://linux.die.net/lkmpg/x121.html 
 * hello.c - The simplest kernel module.
 */
#include <linux/module.h>	/* Needed by all modules */
#include <linux/kernel.h>	/* Needed for KERN_INFO */

MODULE_LICENSE("GPL");

int init_module(void)
{
	printk(KERN_INFO "Atomic kernel module T1014 loaded.\n");

	/* 
	 * A non 0 return means init_module failed; module can't be loaded. 
	 */
	return 0;
}

void cleanup_module(void)
{
	printk(KERN_INFO "Atomic kernel module T1014 unloaded.\n");
}
