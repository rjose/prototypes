include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = proto7
proto7_OBJC_FILES = proto7.m WSFrame.m ./lib/HttpRequest.m ./lib/HttpResponse.m
proto7_C_FILES = ./lib/tcp_io.c ./lib/http_header.c
proto7_LDFLAGS = -lssl
ADDITIONAL_FLAGS += -I./lib

include $(GNUSTEP_MAKEFILES)/tool.make
