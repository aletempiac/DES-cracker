#include <linux/init.h>
#include <linux/module.h>
#include <linux/io.h>
#include <linux/uaccess.h>
#include <linux/device.h>
#include <linux/platform_device.h>
#include <linux/cdev.h>

#define DRIVER_NAME "DES"
#define COMPATIBLE_STRING	"xlnx,des-cracker-1.0"

/* Macro that defines informations about the kernel module*/
MODULE_AUTHOR("Mambelli, Tempia Calvino");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION(DRIVER_NAME ": software driver for DES");
MODULE_ALIAS(DRIVER_NAME);
MODULE_INFO(intree, "Y"); // declare module as in-tree to avoid "tainted kernel" warning

struct resource *res;     // structure used to access resources of hardware device from device tree
unsigned long remap_size; // size of address space of hardware device
void __iomem *base_addr;  // virtual base address of hardware device
static dev_t dev;         // device major/minor numbers
static struct cdev c_dev; // structure used to represent a character device
static struct class *cl;  // structure used to represent a device class

/* called on device open. does nothing. return 0 (no error). */
static int des_open(struct inode *inode, struct file *fp)
{
	return 0;
}

/* called on device close. does nothing. return 0 (no error). */
static int des_close(struct inode *inode, struct file *fp)
{
	return 0;
}

/* called on device read. read 8 bytes (data and status). */
static ssize_t des_read(struct file *fp, char *buf, size_t count, loff_t * f_pos)
{
	uint64_t data; // read data
  int tmp = 42;  // used to check endianess

	rmb(); // memory read barrier

  if(*(char *)&tmp == 42)
  { // little endian
    data = ioread32(base_addr + 4);
    data <<= 32;
    data |= ioread32(base_addr);
  }
  else
  { // big endian
    data = ioread32(base_addr);
    data <<= 32;
    data |= ioread32(base_addr + 4);
  }
	if(copy_to_user(buf,&data,sizeof(uint64_t))) // copy read data to user space
	{
		return -EACCES; // if error return -EACCES error code
	}
	return sizeof(uint64_t); // return number of read bytes
}

/* supported file operations */
static const struct file_operations des_operations = {
  .owner = THIS_MODULE,
	.open = des_open,
	.release = des_close,
	.read = des_read,
};

/* called when removing module */
static int des_remove(struct platform_device *pdev)
{
	device_destroy(cl, dev);                    // remove device from class
	class_destroy(cl);                          // delete class
	cdev_del(&c_dev);                           // delete cdev structure
	unregister_chrdev_region(dev,1);            // unregister device major number
	iounmap(base_addr);                         // unmap base address
	release_mem_region(res->start, remap_size); // deallocate physical address space
  printk(KERN_INFO DRIVER_NAME " module removed.\n");
  printk(KERN_INFO DRIVER_NAME " YOUR BYE MESSAGE\n");
	return 0;
}

/* This function is called when the module is linked to the kernel. The
 * difference with the classic init function is that we have acces to
 * information on the device defined in the device tree. This information is in
 * the platform_device structure */
static int des_probe(struct platform_device *pdev)
{
	int ret = 0;            // return values (error code), 0=no error
	struct device *dev_ret; // structure representing device

	/* get information about the memory ressources from device tree */
	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	if(!res) {
		dev_err(&pdev->dev, "no memory ressource found\n");
		return -ENODEV;
	}

  /* try to allocate physical address space of device */
	remap_size = res->end - res->start + 1;
	if(!request_mem_region(res->start, remap_size, pdev->name)) {
		dev_err(&pdev->dev, "could not reserve IO address range\n");
		return -ENXIO;
	}

  /* remap allocated physical address space to virtual address space */
	base_addr = ioremap(res->start, remap_size);
	if (base_addr == NULL) {
		dev_err(&pdev->dev, "could not ioremap memory at 0x%08lx\n", (unsigned long)res->start);
		ret = -ENOMEM;
		goto err_release_region;
	}

	if((ret = alloc_chrdev_region(&dev, 0, 1, "des"))) // request device major number
	{
		dev_err(&pdev->dev, "could not allocate device major number\n");
		goto err_unmap;
	}

	cdev_init(&c_dev, &des_operations);    // initialize cdev structure

	if((ret = cdev_add(&c_dev, dev, 1)) < 0) // register cdev structure to kernel, with device major number dev
	{
		dev_err(&pdev->dev, "couldn't add the cdev structure\n");
		goto err_unregister;
	}

	if(IS_ERR(cl = class_create(THIS_MODULE, "des"))) // create device class
	{
		dev_err(&pdev->dev, "could not create device class\n");
		goto err_delete_cdev;
	}

	if(IS_ERR(dev_ret = device_create(cl, NULL, dev, NULL, "des"))) // populate device info under class
	{
		dev_err(&pdev->dev, "error in device create\n");
		goto err_class_destroy;
	}
  	printk(KERN_INFO DRIVER_NAME " module loaded.\n");
	printk(KERN_INFO DRIVER_NAME " mapped at virtual address 0x%08lx\n", (unsigned long) base_addr);
	printk(KERN_INFO DRIVER_NAME " YOUR HELLO MESSAGE\n");
	return 0;

err_class_destroy:
	class_destroy(cl);
err_delete_cdev:
	cdev_del(&c_dev);
err_unregister:
	unregister_chrdev_region(dev,1);
err_unmap:
	iounmap(base_addr);
err_release_region:
	release_mem_region(res->start, remap_size);
	return ret;
}

/* This structure contains all the compatible strings of the devices the driver
 * can work with. The last element of the list must be empty */
static const struct of_device_id des_of_match[] = {
	{.compatible  = COMPATIBLE_STRING},
	{},
};

/* Format the structure of_device_id */
MODULE_DEVICE_TABLE(of, des_of_match);

/* We assemble all the functions and structures previously defined in this
 * structure. It will be passed to the macro that register the module to the
 * kernel */
static struct platform_driver des_drv = {
	.driver = {
		.name = DRIVER_NAME,
		.owner = THIS_MODULE,
		.of_match_table = des_of_match},
	.probe = des_probe,
	.remove = des_remove
};

/* This macro is used to register the module to the kernel. It creates the
 * __init and __exit functions and bind them with the module_init() and
 * module_exit() macros */
module_platform_driver(des_drv);
