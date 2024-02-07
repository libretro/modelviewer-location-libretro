
ifeq ($(platform),)
platform = unix
ifeq ($(shell uname -a),)
   platform = win
else ifneq ($(findstring MINGW,$(shell uname -a)),)
   platform = win
else ifneq ($(findstring Darwin,$(shell uname -a)),)
   platform = osx
else ifneq ($(findstring win,$(shell uname -a)),)
   platform = win
endif
endif

TARGET_NAME := modelviewer_location

INCFLAGS = -I. -Iengine

ifneq (,$(findstring unix,$(platform)))
   TARGET := $(TARGET_NAME)_libretro.so
   fpic := -fPIC
   SHARED := -shared -Wl,--version-script=link.T -Wl,--no-undefined
ifneq (,$(findstring gles,$(platform)))
   GLES = 1
else
   GL_LIB := -lGL
endif
   LIBS := -lz
else ifneq (,$(findstring osx,$(platform)))
   TARGET := $(TARGET_NAME)_libretro.dylib
   fpic := -fPIC -mmacosx-version-min=10.6
   SHARED := -dynamiclib
   GL_LIB := -framework OpenGL
   LIBS += -lz
   INCFLAGS += -Iinclude/compat
   DEFINES := -DOSX
   CXXFLAGS += $(DEFINES)
else ifeq ($(platform), ios)
	TARGET := $(TARGET_NAME)_libretro_ios.dylib
	fpic := -fpic
	SHARED := -dynamiclib
	GL_LIB := -framework OpenGLES
	LIBS += -lz
   GLES = 1
	CXX = clang++ -arch armv7 -isysroot $(IOSSDK) -miphoneos-version-min=5.0
	CXXFLAGS += -miphoneos-version-min=5.0
	DEFINES := -DIOS
	CXXFLAGS += $(DEFINES)
   INCFLAGS += -Iinclude/compat
else ifeq ($(platform), pi)
   TARGET := $(TARGET_NAME)_libretro.so
   fpic := -fPIC
   SHARED := -shared -Wl,--version-script=link.T -Wl,--no-undefined
	CXXFLAGS += -I/opt/vc/include -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/vmcs_host/linux
	GLES = 1
	LIBS += -L/opt/vc/lib -lz
else ifeq ($(platform), qnx)
   TARGET := $(TARGET_NAME)_libretro_qnx.so
   fpic := -fPIC
   SHARED := -lcpp -lm -shared -Wl,-version-script=link.T -Wl,-no-undefined
   CXX = QCC -Vgcc_ntoarmv7le_cpp
   AR = QCC -Vgcc_ntoarmv7le
   GLES = 1
   INCFLAGS += -Iinclude/compat
   LIBS := -lz
else ifeq ($(platform), sncps3)
   TARGET := $(TARGET_NAME)_libretro_ps3.a
   CC = $(CELL_SDK)/host-win32/sn/bin/ps3ppusnc.exe
   CXX = $(CELL_SDK)/host-win32/sn/bin/ps3ppusnc.exe
   AR = $(CELL_SDK)/host-win32/sn/bin/ps3snarl.exe
   DEFINES := -D__CELLOS_LV2__
	INCFLAGS += -Iinclude/compat
	STATIC_LINKING = 1
else ifneq (,$(findstring armv,$(platform)))
   CC = gcc
   CXX = g++
   TARGET := $(TARGET_NAME)_libretro.so
   fpic := -fPIC
   SHARED := -shared -Wl,--version-script=link.T -Wl,--no-undefined
   CXXFLAGS += -I.
   LIBS := -lz
ifneq (,$(findstring gles,$(platform)))
   GLES := 1
else
   GL_LIB := -lGL
endif
ifneq (,$(findstring cortexa8,$(platform)))
   CXXFLAGS += -marm -mcpu=cortex-a8
else ifneq (,$(findstring cortexa9,$(platform)))
   CXXFLAGS += -marm -mcpu=cortex-a9
endif
   CXXFLAGS += -marm
ifneq (,$(findstring neon,$(platform)))
   CXXFLAGS += -mfpu=neon
   HAVE_NEON = 1
endif
ifneq (,$(findstring softfloat,$(platform)))
   CXXFLAGS += -mfloat-abi=softfp
else ifneq (,$(findstring hardfloat,$(platform)))
   CXXFLAGS += -mfloat-abi=hard
endif
   CXXFLAGS += -DARM
else ifneq (,$(findstring win,$(platform)))
   CXX = g++
   TARGET := $(TARGET_NAME)_libretro.dll
   SHARED := -shared -static-libgcc -static-libstdc++
   ifneq ($(DEBUG), 1)
   SHARED += -s
   endif  
   SHARED += -Wl,--version-script=link.T -Wl,--no-undefined
ifneq (,$(findstring opengl,$(platform)))
   GL_LIB := -lopengl32
endif
   LIBS := -lz
   INCFLAGS += -Iinclude/win32
endif

CXXFLAGS += $(INCFLAGS)
CFLAGS += $(INCFLAGS)

ifeq ($(DEBUG), 1)
   CXXFLAGS += -O0 -g
else
   CXXFLAGS += -O3
endif

SOURCES := $(wildcard *.cpp) $(wildcard engine/*.cpp) $(wildcard *.c)
OBJECTS := $(SOURCES:.cpp=.o)

ifeq ($(platform), sncps3)
CXXFLAGS += $(fpic)
else
CXXFLAGS += -Wall $(fpic)
endif

ifeq ($(GLES), 1)
   CXXFLAGS += -DGLES
ifeq ($(platform), ios)
   LIBS += $(GL_LIB)
else
   LIBS += -lGLESv2
endif
else
   LIBS += $(GL_LIB)
endif

all: $(TARGET)

$(TARGET): $(OBJECTS)
ifeq ($(STATIC_LINKING), 1)
	$(AR) rcs $@ $(OBJECTS)
else
	$(CXX) $(fpic) $(SHARED) $(INCLUDES) -o $@ $(OBJECTS) $(LIBS) -lm
endif

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJECTS) $(TARGET)

.PHONY: clean

