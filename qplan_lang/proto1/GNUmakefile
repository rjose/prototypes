
include $(GNUSTEP_MAKEFILES)/common.make


TOOL_NAME = proto
proto_C_FILES = proto.c lex.yy.c 
#proto_LDFLAGS = -llua52 -lpthread -lreadline 
CC_LDFLAGS = -lfl

include $(GNUSTEP_MAKEFILES)/tool.make

lex.yy.c: proto.l
	flex proto.l
