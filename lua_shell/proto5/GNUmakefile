include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = proto
proto_OBJC_FILES = proto.m listen.m
proto_C_FILES = tcp_io.c
proto_OBJCFLAGS = -I/usr/local/include/lua52
proto_LDFLAGS = -llua-5.2 -lreadline

include $(GNUSTEP_MAKEFILES)/tool.make
