# ngwinbuild
My windows build with nmake for NGHTTP2 

    Requires:
    perl (in your system path) 
    Visual Studio or a Windows SDK with the compilers installed.


    To use:
    Copy the entire win32 folder into nghttp2's source root.
    Example: C:\build\nghttp2-1.15.0

    Open a VC++ Command prompt (x86 or x64)
    cd to nghttp2's lib folder (cd \build\nghttp2-1.15.0\lib)
    then these commands
        ..\win32\ngwinbuild
        nmake (for x86 builds)
        nmake arch=x64 (to build x64)

        nmake instdir=\path\to\some\folder install
        (Example: nmake instdir=\build\httpd-2.4.24\srclib install )

    Using the above example you will end up with
    c:\build\httpd-2.4.24\srclib\nghttp2
    c:\build\httpd-2.4.24\srclib\nghttp2\includes
    c:\build\httpd-2.4.24\srclib\nghttp2\MSVC_obj

    The latter includes both release & debug static libs and dlls

