CC = gcc
CFLAGS = -O2 -Wall
BINDIR = ../bin

all: \
	$(BINDIR)/inplace_instruction_overwrite \
	$(BINDIR)/instruction_overwrite_jump \
	$(BINDIR)/got_injection \
	$(BINDIR)/rop_mprotect_return_address_overwrite \
	$(BINDIR)/return_address_overwrite \
	$(BINDIR)/return_address_overwrite_fullROPchain

$(BINDIR)/inplace_instruction_overwrite: inplace_instruction_overwrite.c
	$(CC) $(CFLAGS) $< -o $@

$(BINDIR)/instruction_overwrite_jump: instruction_overwrite_jump.c
	$(CC) $(CFLAGS) $< -o $@

$(BINDIR)/got_injection: got_injection.c
	$(CC) $(CFLAGS) $< -o $@

$(BINDIR)/rop_mprotect_return_address_overwrite: rop_mprotect_return_address_overwrite.c
	$(CC) $(CFLAGS) $< -o $@

$(BINDIR)/return_address_overwrite: return_address_overwrite.c
	$(CC) $(CFLAGS) $< -o $@

$(BINDIR)/return_address_overwrite_fullROPchain: retAddr_overwrite_fullROPchain_inj.c
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f $(BINDIR)/*
