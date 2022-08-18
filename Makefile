# contrib/pg_tokenparser/Makefile

MODULE_big = pg_tokenparser
OBJS = \
	$(WIN32RES) \
	pg_tokenparser.o
PGFILEDESC = "pg_tokenparser - self-defined token parser"

PG_CPPFLAGS = -I$(libpq_srcdir)
SHLIB_LINK_INTERNAL = $(libpq)

EXTENSION = pg_tokenparser
DATA = pg_tokenparser--1.0.sql

REGRESS = pg_tokenparser # sql、expected 文件夹下的测试，

ifdef USE_PGXS
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
else
SHLIB_PREREQS = submake-libpq
subdir = contrib/pg_tokenparser
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif
