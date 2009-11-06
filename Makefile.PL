use 5.008009;
use inc::Module::Install;
name 'CSS-Croco';
all_from 'lib/CSS/Croco.pm';
requires 'URI';
repository 'http://developers.rambler.ru/svn/perlmodules';
system("pkg-config libcroco-0.6") and die "NA: libcroco-0.6 is not available. Please intall it and try again";
WriteMakefile(
    CCFLAGS => `pkg-config --cflags libcroco-0.6`,
    LIBS => [ `pkg-config --libs libcroco-0.6` ],
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    XSOPT => '-prototypes',
);
