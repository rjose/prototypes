include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = proto6
proto6_OBJC_FILES = proto6.m ./lib/WSFrame.m ./lib/HttpRequest.m ./lib/HttpResponse.m
proto6_C_FILES = ./lib/tcp_io.c ./lib/http_header.c
proto6_LDFLAGS = -lssl
ADDITIONAL_FLAGS += -I./lib

include $(GNUSTEP_MAKEFILES)/tool.make
