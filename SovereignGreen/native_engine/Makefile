CC=gcc
CFLAGS=-shared -fPIC

all: libenergy.so

libenergy.so: energy_math.c
	$(CC) $(CFLAGS) -o libenergy.so energy_math.c

libenergy.dll: energy_math.c
	$(CC) -shared -o libenergy.dll energy_math.c

clean:
	rm -f libenergy.so libenergy.dll
