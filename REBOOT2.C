#define INCL_BASE
#include <os2.h>

char			device_name[] = "REBOOTZZ";

main()
{
	USHORT		action;
	int			err;
	HFILE			handle;

	err = DosOpen(device_name,
						&handle,
						&action,
						0L,				// size
						0,					// attribute
						1,					// open the file
						0x42,	 			// read/write, deny-none share mode
						0L);				// reserved

	if (err)
		printf("DosOpen on device %s failed.  Err = 0x%x.\n", 
               device_name, err);

}




