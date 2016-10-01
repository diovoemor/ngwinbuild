@rem #############################################################
@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
@perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
@perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!perl
#line 15
###############################################################################
# Script Name: NGWinbuild                                                     #
# Filename: ngwinbuild.bat                                                    #
# Date: September 27, 2016                                                    #
# Copyright (c) 2016,  Gregg Smith                                            #
# Licensed under The MIT License (MIT)                                        #
###############################################################################
use strict;
#use warnings; # for debugging
use Cwd;
my $cwd = getcwd; 
unless ($cwd =~ /nghttp2/ && $cwd =~ /lib$/) {
&usage;
exit 1;
}

system('cls');
mkdir 'MSVC_obj' unless (-d 'MSVC_obj');

my $dir='./';
my $outmak = 'Makefile';
my $outrc = 'MSVC_obj/nghttp2.rc';
my $ver_h_in = 'includes/nghttp2/nghttp2ver.h.in';
my $ver_h_out = 'includes/nghttp2/nghttp2ver.h';
my $vinfo = '../configure.ac';
my ($timestamp, $yool) = yool();

## Get template data
my $DATA = join("", <DATA>);
my ($RCF,$MKF,$INSTRUCT) = split(/<SPLITDATA>/,$DATA);

## VERSIONINFO
my @ver_h = read_file($ver_h_in);
my @vinfo = read_file($vinfo);
@vinfo = grep(/^AC_INIT/,@vinfo);
@vinfo = ($vinfo[0] =~ /((\d+)\.(\d+)\.(\d+))/);
my $verfull = $vinfo[0];
my $vmaj = $vinfo[1]; my $vmin = $vinfo[2]; my $vrev = $vinfo[3];
my $h = $vmaj < 10 ? '0'.$vmaj : $vmaj;
my $e = $vmin < 10 ? '0'.$vmin : $vmin;
my $x = $vrev < 10 ? '0'.$vrev : $vrev;
my $verhex = '0x'.$h.$e.$x; undef $h,$e,$x,@vinfo;
print 'NGHTTP2 Version'."\n".'---------------'."\n";
print 'Major:    '.$vmaj."\n";
print 'Minor:    '.$vmin."\n";
print 'Revision: '.$vrev."\n\n";
print 'Generating Versioninfo: '.$ver_h_out."\n";

## lib/MSVC_obj/nghttp2ver.h
open(WRI,">".$ver_h_out) || die "Can't open $ver_h_out for output";
foreach (@ver_h) {
  my $line = filter_line($_,$verfull,$verhex,$vmaj,$vmin,$vrev);
  print WRI $line."\n";
}
close(WRI);

## RESOURCE FILE
$RCF = filter_line($RCF,$verfull,$verhex,$vmaj,$vmin,$vrev,$timestamp,$yool);
print 'Generating Resource File: '.$outrc."\n";
open(WRI,">".$outrc) || die "Cannot open $outrc for output";
  print WRI $RCF."\n";
close(WRI);

## NATIVE MSVC MAKE FILE
$MKF = filter_line($MKF,$verfull,$verhex,$vmaj,$vmin,$vrev);
print 'Generating NMake Makefile.'."\n";
open(WRI,">".$outmak) || die "Cannot open $outmak for output";
  print WRI $MKF."\n";
close(WRI);

# and we are done
print "Configuration done\n\n";
print $INSTRUCT."\n\n";

# goodbye
exit 0; 

sub filter_line {
  my (@passed)=@_;
  my $line = $passed[0];
  if ($line =~ /\@OBJS\@/) {
    my $files = get_nfiles();
    $line =~ s|\@OBJS\@|$files|;
  }
  $line =~ s|\@PACKAGE_VERSION\@|$passed[1]|;
  $line =~ s|\@VERSTRN\@|$passed[1]|;
  $line =~ s|\@PACKAGE_VERSION_NUM\@|$passed[2]|;
  $line =~ s|\@VMAJ\@|$passed[3]|;  
  $line =~ s|\@VMIN\@|$passed[4]|;
  $line =~ s|\@VREV\@|$passed[5]|;
  $line =~ s|\@TIMESTAMP\@|$passed[6]|;
  $line =~ s|\@NGYEAR\@|$passed[7]|;
#  $line =~ s|||;
  return $line;
} # End filter_line

sub read_file {
  my $thefile = shift;
  my @thecontents;
  if (-e $thefile) {
    open(READ,$thefile); 
    @thecontents = <READ>;
    close(READ);
  }
  else {
     print 'ERROR: Cannot find file '.$thefile;
     exit 0; 
  }
  chomp(@thecontents);
  return @thecontents;
} # End read_file

sub read_dir {
  my $thedir = shift;
  opendir (INDEX, $thedir);
  my @thefiles = grep (/^nghttp2\w+\.c/, readdir (INDEX));
  closedir (INDEX);
  return @thefiles;
} # End read_dir 

sub yool {
  my $time = time;
  my (@yool) = localtime($time);
  my $timestamp = localtime($time);
  return $timestamp, ($yool[5]+1900);
}

sub get_nfiles {
  my $i=0;
  my $nline;
  my @fcontents = read_dir('./');
  foreach my $file (@fcontents) {
    $file =~ s|\.c$||i;
    $nline .= $file.' ';
    $i++;
    if ($i==4) {
      $nline .= "\\\n           ";
      $i=0;
    }
  }
  return $nline;
}
sub usage {
print "NGWinbuild must be run from the sources /lib folder\nExample:\n\n";
print "  \$   cd\\path\\to\\nghttp2-x.x.x\\lib\n  \$   NGWinbuild\n\n";
}
###############################################################################
#                                  __DATA__                                   #
###############################################################################

__DATA__

  #include <winver.h>

  #ifdef _WIN64
  #define ARCH "64"
  #else
  #define ARCH "32"
  #endif

  #define NGHTTP2_COPYRIGHT     "Copyright (c) 2012-@NGYEAR@, Tatsuhiro Tsujikawa"
  #define NGHTTP2_TIMESTAMP     "@TIMESTAMP@"

  #define NGHTTP2_VER_MAJOR     @VMAJ@
  #define NGHTTP2_VER_MINOR     @VMIN@
  #define NGHTTP2_VER_REVISION  @VREV@
  #define NGHTTP2_VERSIONSTR    "@VERSTRN@"

  VS_VERSION_INFO VERSIONINFO
    FILEVERSION    NGHTTP2_VER_MAJOR, NGHTTP2_VER_MINOR, NGHTTP2_VER_REVISION, 0
    PRODUCTVERSION NGHTTP2_VER_MAJOR, NGHTTP2_VER_MINOR, NGHTTP2_VER_REVISION, 0
    FILEFLAGSMASK  0x3fL
    FILEOS         0x40004L
    FILETYPE       0x2L
    FILESUBTYPE    0x0L
  #ifdef _DEBUG
    #define        NGVERSTR  NGHTTP2_VERSIONSTR " (MSVC Win" ARCH " debug)"
    #define        NGDEBUG      "d"
    FILEFLAGS      0x1L
  #else
    #define        NGVERSTR  NGHTTP2_VERSIONSTR " (MSVC Win" ARCH " release)"
    #define        NGDEBUG      ""
    FILEFLAGS      0x0L
  #endif
  BEGIN
    BLOCK "StringFileInfo"
    BEGIN
      BLOCK "040904b0"
      BEGIN
        VALUE "FileDescription",  "nghttp2; HTTP/2 C library"
        VALUE "FileVersion",      NGVERSTR
        VALUE "InternalName",     "nghttp2" NGDEBUG
        VALUE "LegalCopyright",   NGHTTP2_COPYRIGHT
        VALUE "OriginalFilename", "nghttp2" NGDEBUG ".dll"
        VALUE "ProductName",      "NGHTTP2"
        VALUE "ProductVersion",   NGVERSTR
        VALUE "BuildDate",        NGHTTP2_TIMESTAMP "\0"
      END
    END
  BLOCK "VarFileInfo"
  BEGIN
    VALUE "Translation", 0x409, 1200
  END
  END

<SPLITDATA>###############################################################################
# NMake Makefile for Microsoft Visual Studio                                  #
# Generated by NGWinbuild                                                     #
###############################################################################
NAME     = nghttp2

!IF "$(ARCH)" == "x64"
RCFLAGS  = -D_WIN64
!ELSEIF "$(ARCH)" == "X64"
RCFLAGS  = -D_WIN64
!ELSE
ARCH     = x86
!ENDIF

CC       = @CL
LL       = @LINK
LB       = @LIB
MT       = @MT
RC       = @RC

CFLAGS   = /I includes /Dssize_t=long /D_U_="" /D_CRT_SECURE_NO_WARNINGS
CFLAGSR  = /nologo /MD  /W3 /Z7 /DBUILDING_NGHTTP2
CFLAGSD  = /nologo /MDd /W3 /Z7 /DBUILDING_NGHTTP2 \
           /Ot /D_DEBUG /GF /RTCs /RTCu # -RTCc -GS

LFLAGS   = /nologo /dll /MAP /debug /incremental:no /opt:ref,icf /subsystem:windows /manifest /machine:$(ARCH)
LBFLAGS  = /nologo /machine:$(ARCH)

DLLR     = $(OBJDIR)/$(NAME).dll
DLLD     = $(OBJDIR)/$(NAME)d.dll
IMPR     = $(OBJDIR)/nghttp2.lib
IMPD     = $(OBJDIR)/nghttp2d.lib
LIBR     = $(OBJDIR)/nghttp2-static.lib
LIBD     = $(OBJDIR)/nghttp2d-static.lib
PDBR     = $(OBJDIR)/nghttp2.pdb
PDBD     = $(OBJDIR)/nghttp2d.pdb

OBJDIR   = MSVC_obj
OBJS     = @OBJS@

all: intro objects resource linker libsgen houseclean outro

intro:
  @echo ###############################
  @echo # Building NgHTTP2 (MSVC) $(ARCH) #
  @echo ###############################

objects: 
#!MESSAGE Building object files
  @echo.    
  @echo # Compiling source files.
  @echo.    
  @for %f in ($(OBJS)) do \
    $(CC) $(CFLAGSR) $(CFLAGS) /Fo$(OBJDIR)\r_%f.obj -c %f.c
  @for %f in ($(OBJS)) do \
    $(CC) $(CFLAGSD) $(CFLAGS) /Fo$(OBJDIR)\d_%f.obj -c %f.c

linker:
  @echo.    
  @echo # Creating Dlls (Release and Debug).
  @echo.    
  $(LL) $(LFLAGS) $(OBJDIR)\$(NAME).res /out:$(DLLR) $(OBJDIR)\r_*.obj
  $(LL) $(LFLAGS) $(OBJDIR)\$(NAME).res /out:$(DLLD) $(OBJDIR)\d_*.obj

libsgen:
  @echo.    
  @echo # Creating static libraries (Release and Debug).
  @echo.    
  $(LB) $(LBFLAGS) /out:$(LIBR) $(OBJDIR)\r_*.obj
  $(LB) $(LBFLAGS) /out:$(LIBD) $(OBJDIR)\d_*.obj

resource:
  $(RC) $(RCFLAGS) /fo$(OBJDIR)\$(NAME).res $(OBJDIR)\$(NAME).rc

houseclean:
  @echo.    
  @echo # Doing a little cleanup.
  @del /f $(OBJDIR)\*.obj $(OBJDIR)\*.manifest $(OBJDIR)\*.map $(OBJDIR)\*.res
  @echo # Done.
  @echo.    

outro:
  @echo ###############################
  @echo # Building NgHTTP2 Complete   #
  @echo ###############################

install:
!IF "$(INSTDIR)" == ""
# sigh
  @echo You need to supply a directory to install NGHTTP2 into! (use instdir)
  @echo    Example:  nmake instdir=C:\nghttp2 install
!ELSEIF !EXIST ("$(INSTDIR)")
# scratching head
  @echo Could not find $(INSTDIR)
  @echo Please try again installing to a directory that exists.
!ELSE IF EXIST ("$(INSTDIR)\..\nghttp2")
# Are we in an existing nghttp2 directory? Let's not make another inside it
  @echo Installing NGHTTP2 to $(INSTDIR)
  @copy /y ..\COPYING  $(INSTDIR)\COPYING
  @xcopy /s /v /y includes\nghttp2\*.h $(INSTDIR)\lib\includes\nghttp2\*.h
  @xcopy /s /v /y $(OBJDIR)\*.* $(INSTDIR)\lib\$(OBJDIR)\*.*
  @del /q $(INSTDIR)\lib\$(OBJDIR)\nghttp2.rc
  @echo NGHTTP2 installed to $(INSTDIR)
!ELSE IF !EXIST ("$(INSTDIR)\nghttp2")
# If $(INSTDIR)\nghttp2 doesn't exist, make it exist.
  md $(INSTDIR)\nghttp2
  @echo Installing NGHTTP2 to $(INSTDIR)\nghttp2
  @copy /y ..\COPYING  $(INSTDIR)\nghttp2\COPYING
  @xcopy /s /v /y includes\nghttp2\*.h $(INSTDIR)\nghttp2\lib\includes\nghttp2\*.h
  @xcopy /s /v /y $(OBJDIR)\*.* $(INSTDIR)\nghttp2\lib\$(OBJDIR)\*.*
#  @del /q $(INSTDIR)\nghttp2\lib\$(OBJDIR)\nghttp2.rc
  @echo NGHTTP2 installed to $(INSTDIR)\nghttp2
!ELSE
!IF EXIST ("$(INSTDIR)")
# I hope I got this right. If the user falls short of the mark and a nghttp2
# directory already exists in $(INSTDIR), use it. If I got it wrong, it will
# just error and not install, I hope, a fatal when copying COPYING and exit.
  @echo Installing NGHTTP2 to $(INSTDIR)\nghttp2
  @copy /y ..\COPYING  $(INSTDIR)\nghttp2\COPYING
  @xcopy /s /v /y includes\nghttp2\*.h $(INSTDIR)\nghttp2\lib\includes\nghttp2\*.h
  @xcopy /s /v /y $(OBJDIR)\*.* $(INSTDIR)\nghttp2\lib\$(OBJDIR)\*.*
  @del /q $(INSTDIR)\nghttp2\lib\$(OBJDIR)\nghttp2.rc
  @echo NGHTTP2 installed to $(INSTDIR)\nghttp2
!ELSE
# Who'd of thunk it?
  @echo Something went horribly wrong. I blame myself for not thinking of
  @echo this possibility. NGHTTP2 NOT INSTALLED.
!ENDIF
!ENDIF

clean:
  @del /q $(OBJDIR)\*.dll $(OBJDIR)\*.exp $(OBJDIR)\*.lib $(OBJDIR)\*.pdb
  @echo Cleaning completed.

vclean:
  @rmdir /s /q $(OBJDIR)
  @del /f includes\nghttp2\nghttp2ver.h
  @del /f Makefile
  @echo Full cleaning completed.

<SPLITDATA>
  # To build 32bit binaries
  $  nmake

  # To build 64bit binaries
  $  nmake arch=x64

  # To remove generated binaries and other files yet still buildable by nmake
  $  nmake clean

  # To remove everything generated
  $  nmake vclean

  # To build after a vclean, just rerun this file.

<SPLITDATA>#

__END__
:endofperl
