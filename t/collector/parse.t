
=head1 DESCRIPTION

This tests the L<CPAN::Testers::Collector::Parse> module which parses the
text output by a reporter and fills in the metadata as it can.

=cut

use Mojo::Base -signatures;
use Test2::V0;
use CPAN::Testers::Collector::Parse;
use Mojo::Loader qw( data_section );
use Data::Dumper qw( Dumper );

subtest 'prerequisites' => sub {
  subtest 'CPAN-Reporter-1.2020' => sub {
    my $report = {};
    my @lines = split /\n/, data_section('main', 'prerequisites-cpan-reporter-1.2020.txt');
    CPAN::Testers::Collector::Parse::_parse_prerequisites($report, @lines);
    like $report->{distribution}{prerequisites}, subset {
      item {
        phase => 'requires',
        name => 'Bitcoin::BIP39',
        need => '0.002',
        have => '0.003',
      };
      item {
        phase => 'requires',
        name => 'CryptX',
        need => '0.074',
        have => '0.087_007',
      };
      item {
        phase => 'build',
        name => 'ExtUtils::MakeMaker',
        need => '0',
        have => '7.78',
      };
      item {
        phase => 'configure',
        name => 'ExtUtils::MakeMaker',
        need => '0',
        have => '7.78',
      };
    }, 'prerequisites' or diag Dumper $report;
  };

  subtest 'prerequisites-cpanminus-reporter-0.18-not-found.txt' => sub {
    my $report = {};
    my @lines = split /\n/, data_section('main', 'prerequisites-cpanminus-reporter-0.18-not-found.txt');
    CPAN::Testers::Collector::Parse::_parse_prerequisites($report, @lines);
    is $report->{distribution}{prerequisites}, undef;
  };

  subtest 'CPANPLUS-0.9178' => sub {
    my $report = {};
    my @lines = split /\n/, data_section('main', 'prerequisites-cpanplus-0.9178.txt');
    CPAN::Testers::Collector::Parse::_parse_prerequisites($report, @lines);

    like $report->{distribution}{prerequisites}, subset {
      item {
        phase => 'requires',
        name => 'Data::Sah::Util::Type',
        need => '0.45',
        have => '0.46',
      };
    }, 'prerequisites' or diag Dumper $report;

    like $report->{environment}{system}{toolchain}, hash {
      field 'CPANPLUS', '0.9178';
      etc();
    }, 'toolchain' or diag Dumper $report;
  };

  subtest 'cpanminus-reporter-0.12-with-missing' => sub {
    my $report = {};
    my @lines = split /\n/, data_section('main', 'prerequisites-cpanminus-reporter-0.12-with-missing.txt');
    CPAN::Testers::Collector::Parse::_parse_prerequisites($report, @lines);

    like $report->{distribution}{prerequisites}, subset {
      item {
        phase => 'runtime',
        name => 'Carp',
        need => '0',
        have => '1.26',
      };
      item {
        phase => 'runtime',
        name => 'Devel::StackTrace',
        need => '1.32',
        have => 'n/a',
      };
    }, 'prerequisites' or diag Dumper $report;
  };

  subtest 'report-prereqs-test' => sub {
    my $report = {};
    my @lines = split /\n/, data_section('main', 'prerequisites-report-prereqs-test.txt');
    CPAN::Testers::Collector::Parse::_parse_prerequisites($report, @lines);

    like $report->{distribution}{prerequisites}, subset {
      item {
        phase => 'configure',
        name => 'ExtUtils::MakeMaker',
        need => '0',
        have => '7.04',
      };
      item {
        phase => 'test',
        name => 'File::Spec',
        need => '0',
        have => '3.47',
      };
      item {
        phase => 'test_recommends',
        name => 'CPAN::Meta',
        need => '2.120900',
        have => '2.120630',
      };
      item {
        phase => 'runtime',
        name => 'Moo::Role',
        need => '0',
        have => '2.000001',
      };
    }, 'prerequisites' or diag Dumper $report;
  };
};

subtest 'environment' => sub {
  subtest 'CPAN-Reporter-1.2020' => sub {
    my $report = {};
    my @lines = split /\n/, data_section('main', 'environment-cpan-reporter-1.2020.txt');
    CPAN::Testers::Collector::Parse::_parse_environment($report, @lines);
    like $report->{environment}{system}{variables}, hash {
      field AUTOMATED_TESTING => "1";
      field LANG => "en_US.UTF-8";
      etc();
    }, 'environment variables' or diag Dumper $report;
    like $report->{environment}{language}{variables}, hash {
      field '$GID' => "1005 1005";
      etc();
    }, 'language variables' or diag Dumper $report;
    like $report->{environment}{system}{toolchain}, hash {
      field 'Test::More' => "1.302219";
      etc();
    }, 'toolchain modules' or diag Dumper $report;
  };
};

subtest 'parse' => sub {
  subtest 'CPAN-Reporter-1.2020' => sub {
    my $report = {
      result => {
        output => {
          uncategorized => data_section('main', 'report-cpan-reporter-1.2020.txt'),
        },
      },
    };
    my $output = CPAN::Testers::Collector::Parse->parse($report);
    like $output->{distribution}{prerequisites}, subset {
      item {
        phase => 'requires',
        name => 'Bitcoin::BIP39',
        need => '0.002',
        have => '0.003',
      };
    }, 'prerequisites' or diag Dumper $output;
    like $output->{environment}{system}{variables}, hash {
      field AUTOMATED_TESTING => "1";
      etc();
    }, 'environment variables' or diag Dumper $report;
    like $output->{environment}{language}{variables}, hash {
      field '$GID' => "1005 1005";
      etc();
    }, 'language special variables' or diag Dumper $report;
    like $output->{environment}{system}{toolchain}, hash {
      field 'Test::More' => "1.302219";
      etc();
    }, 'toolchain modules' or diag Dumper $report;
  };

  subtest 'CPAN-Reporter-1.2019 with test summary report' => sub {
    my $report = {
      result => {
        output => {
          uncategorized => data_section('main', 'report-cpan-reporter-1.2019-with-test-summary.txt'),
        },
      },
    };
    my $output = CPAN::Testers::Collector::Parse->parse($report);
    like $output->{distribution}{prerequisites}, subset {
      item {
        phase => 'requires',
        name => 'XML::Writer',
        need => '0',
        have => '0.900',
      };
    }, 'prerequisites' or diag Dumper $output;
    like $output->{environment}{system}{variables}, hash {
      field AUTOMATED_TESTING => "1";
      etc();
    }, 'environment variables' or diag Dumper $report;
    like $output->{environment}{language}{variables}, hash {
      field '$GID' => "1002 1002";
      etc();
    }, 'language special variables' or diag Dumper $report;
    like $output->{environment}{system}{toolchain}, hash {
      field 'Test::More' => "1.302199";
      etc();
    }, 'toolchain modules' or diag Dumper $report;
  };

  subtest 'CPANPLUS-0.9178' => sub {
    my $report = {
      result => {
        output => {
          uncategorized => data_section('main', 'report-cpanplus-0.9178.txt'),
        },
      },
    };
    my $output = CPAN::Testers::Collector::Parse->parse($report);
    like $output->{distribution}{prerequisites}, subset {
      item {
        phase => 'requires',
        name => 'Data::Sah::Util::Type',
        need => '0.45',
        have => '0.46',
      };
    }, 'prerequisites' or diag Dumper $output;
    like $output->{environment}{system}{variables}, hash {
      field AUTOMATED_TESTING => "1";
      etc();
    }, 'environment variables' or diag Dumper $report;
    like $output->{environment}{language}{variables}, hash {
      field '$GID' => "100 100";
      etc();
    }, 'language special variables' or diag Dumper $report;
    like $output->{environment}{system}{toolchain}, hash {
      field 'Test::More' => "1.302164";
      etc();
    }, 'toolchain modules' or diag Dumper $report;
  };

  subtest 'App::cpanminus::reporter 0.12 with 00-report-prereqs' => sub {
    my $report = {
      result => {
        output => {
          uncategorized => data_section('main', 'report-cpanminus-reporter-0.12-with-report-prereqs.txt'),
        },
      },
    };
    my $output = CPAN::Testers::Collector::Parse->parse($report);
    like $output->{distribution}{prerequisites}, subset {
      item {
        phase => 'configure',
        name => 'ExtUtils::MakeMaker',
        need => '0',
        have => '7.04',
      };
    }, 'prerequisites' or diag Dumper $output;
    like $output->{environment}{system}{variables}, hash {
      field PERLBREW_VERSION => "0.73";
      etc();
    }, 'environment variables' or diag Dumper $report;
    like $output->{environment}{language}{variables}, hash {
      field '$GID' => "1003 1003";
      etc();
    }, 'language special variables' or diag Dumper $report;
    like $output->{environment}{system}{toolchain}, hash {
      field 'YAML' => "n/a";
      etc();
    }, 'toolchain modules' or diag Dumper $report;
  };
};

done_testing;
__DATA__

@@ report-cpanminus-reporter-0.18-mswin32-na.txt

This distribution has been tested as part of the CPAN Testers
project, supporting the Perl programming language.  See
http://wiki.cpantesters.org/ for more information or email
questions to cpan-testers-discuss@perl.org


--
Dear PODMASTER,

This is a computer-generated report for Wx-DialUpManager-0.03
on perl 5.42.0, created by App::cpanminus::reporter 0.18 (1.7048).

Thank you for uploading your work to CPAN.  While attempting to build or test
this distribution, the distribution signaled that support is not available
either for this operating system or this version of Perl.  Nevertheless, any
diagnostic output produced is provided below for reference.  If this is not
what you expect, you may wish to consult the CPAN Testers Wiki:

http://wiki.cpantesters.org/wiki/CPANAuthorNotes

Sections of this report:

    * Tester comments
    * Program output
    * Prerequisites
    * Environment and other context

------------------------------
TESTER COMMENTS
------------------------------

Additional comments from tester:

this report is from an automated smoke testing program
and was not reviewed by a human for accuracy

------------------------------
PROGRAM OUTPUT
------------------------------

Output from '':

Running Makefile.PL
Warning: prerequisite Wx::build::MakeMaker not found.
Warning: you need to install wxPerl (http://wxPerl.sf.net).
-> N/A
-> FAIL Configure failed for Wx-DialUpManager-0.03. See C:\Users\smoker\.cpanm\work\1760193086.6452\build.log for details.

------------------------------
PREREQUISITES
------------------------------

Prerequisite modules loaded:

    No requirements found

------------------------------
ENVIRONMENT AND OTHER CONTEXT
------------------------------

Environment variables:

    AUTOMATED_TESTING = 1
    COMSPEC = C:\Windows\system32\cmd.exe
    NUMBER_OF_PROCESSORS = 2
    PATH = C:\WINDOWS\system32;C:\Program Files\Git\cmd;C:\strawberry\c\bin;C:\strawberry\perl\site\bin;C:\strawberry\perl\bin
    PERL5_CPANPLUS_IS_RUNNING = 2748
    PERL5_CPAN_IS_RUNNING = 2748
    PERL_CR_SMOKER_CURRENT = Wx-DialUpManager-0.03
    PERL_EXTUTILS_AUTOINSTALL = --defaultdeps
    PERL_MM_USE_DEFAULT = 1
    PROCESSOR_IDENTIFIER = Intel64 Family 6 Model 15 Stepping 11, GenuineIntel
    TEMP = C:\Users\smoker\AppData\Local\Temp

Perl special variables (and OS-specific diagnostics, for MSWin32):

    EGID = 0
    EUID = 0
    EXECUTABLE_NAME = C:\Strawberry\perl\bin\perl.exe
    GID = 0
    UID = 0
    Win32::FsType = NTFS
    Win32::GetOSName = Win10
    Win32::GetOSVersion = , 10, 0, 19045, 2, 0, 0, 256, 1
    Win32::IsAdminUser = 0

Perl module toolchain versions installed:

    Module              Have    
    ------------------- --------
    CPAN                2.38    
    CPAN::Meta          2.150010
    Cwd                 3.94    
    ExtUtils::CBuilder  0.280242
    ExtUtils::Command   7.76    
    ExtUtils::Install   2.22    
    ExtUtils::MakeMaker 7.76    
    ExtUtils::Manifest  1.75    
    ExtUtils::ParseXS   3.60    
    File::Spec          3.94    
    JSON                4.10    
    JSON::PP            4.16    
    Module::Build       0.4234  
    Module::Signature   n/a     
    Parse::CPAN::Meta   2.150010
    Test::Harness       3.52    
    Test::More          1.302214
    YAML                1.31    
    YAML::Syck          1.34    
    version             0.9933  


--

Summary of my perl5 (revision 5 version 42 subversion 0) configuration:
   
  Platform:
    osname=MSWin32
    osvers=10.0.26100.4652
    archname=MSWin32-x64-multi-thread
    uname='Win32 strawberry-perl 5.42.0.1 # 05:37:25 Fri August 01 2025 x64'
    config_args='undef'
    hint=recommended
    useposix=true
    d_sigaction=undef
    useithreads=define
    usemultiplicity=define
    use64bitint=define
    use64bitall=undef
    uselongdouble=undef
    usemymalloc=n
    default_inc_excludes_dot=define
  Compiler:
    cc='gcc'
    ccflags ='-std=c99 -DWIN32 -DWIN64 -DPERL_TEXTMODE_SCRIPTS -DMULTIPLICITY -DPERL_IMPLICIT_SYS -DUSE_PERLIO -D__USE_MINGW_ANSI_STDIO -fwrapv -fno-strict-aliasing -mms-bitfields'
    optimize='-O2'
    cppflags='-DWIN32'
    ccversion=''
    gccversion='13.2.0'
    gccosandvers=''
    intsize=4
    longsize=4
    ptrsize=8
    doublesize=8
    byteorder=12345678
    doublekind=3
    d_longlong=define
    longlongsize=8
    d_longdbl=define
    longdblsize=16
    longdblkind=3
    ivtype='long long'
    ivsize=8
    nvtype='double'
    nvsize=8
    Off_t='long long'
    lseeksize=8
    alignbytes=8
    prototype=define
  Linker and Libraries:
    ld='g++'
    ldflags ='-s -L"C:\STRAWB~1\perl\lib\CORE" -L"C:\STRAWB~1\c\lib" -L"C:\STRAWB~1\c\x86_64-w64-mingw32\lib" -L"C:\STRAWB~1\c\lib\gcc\x86_64-w64-mingw32\13.2.0"'
    libpth=C:\STRAWB~1\c\lib C:\STRAWB~1\c\x86_64-w64-mingw32\lib C:\STRAWB~1\c\lib\gcc\x86_64-w64-mingw32\13.2.0 C:\STRAWB~1\c\x86_64-w64-mingw32\lib C:\STRAWB~1\c\lib\gcc\x86_64-w64-mingw32\13.2.0
    libs= -lmoldname -lkernel32 -luser32 -lgdi32 -lwinspool -lcomdlg32 -ladvapi32 -lshell32 -lole32 -loleaut32 -lnetapi32 -luuid -lws2_32 -lmpr -lwinmm -lversion -lodbc32 -lodbccp32 -lcomctl32
    perllibs= -lmoldname -lkernel32 -luser32 -lgdi32 -lwinspool -lcomdlg32 -ladvapi32 -lshell32 -lole32 -loleaut32 -lnetapi32 -luuid -lws2_32 -lmpr -lwinmm -lversion -lodbc32 -lodbccp32 -lcomctl32
    libc=-lucrt
    so=dll
    useshrplib=true
    libperl=libperl542.a
    gnulibc_version=''
  Dynamic Linking:
    dlsrc=dl_win32.xs
    dlext=xs.dll
    d_dlsymun=undef
    ccdlflags=' '
    cccdlflags=' '
    lddlflags='-shared -s -L"C:\STRAWB~1\perl\lib\CORE" -L"C:\STRAWB~1\c\lib" -L"C:\STRAWB~1\c\x86_64-w64-mingw32\lib" -L"C:\STRAWB~1\c\lib\gcc\x86_64-w64-mingw32\13.2.0"'


Characteristics of this binary (from libperl): 
  Compile-time options:
    HAS_LONG_DOUBLE
    HAS_TIMES
    HAVE_INTERP_INTERN
    MULTIPLICITY
    PERLIO_LAYERS
    PERL_COPY_ON_WRITE
    PERL_DONT_CREATE_GVSV
    PERL_HASH_FUNC_SIPHASH13
    PERL_HASH_USE_SBOX32
    PERL_IMPLICIT_SYS
    PERL_MALLOC_WRAP
    PERL_OP_PARENT
    PERL_PRESERVE_IVUV
    PERL_USE_SAFE_PUTENV
    USE_64_BIT_INT
    USE_ITHREADS
    USE_LARGE_FILES
    USE_LOCALE
    USE_LOCALE_COLLATE
    USE_LOCALE_CTYPE
    USE_LOCALE_NUMERIC
    USE_LOCALE_TIME
    USE_PERLIO
    USE_PERL_ATOF
    USE_THREAD_SAFE_LOCALE
  Built under MSWin32
  Compiled at Aug  1 2025 15:42:55
  %ENV:
    PERL5_CPANPLUS_IS_RUNNING="2748"
    PERL5_CPAN_IS_RUNNING="2748"
    PERL_CR_SMOKER_CURRENT="Wx-DialUpManager-0.03"
    PERL_EXTUTILS_AUTOINSTALL="--defaultdeps"
    PERL_MM_USE_DEFAULT="1"
  @INC:
    C:/Strawberry/perl/site/lib/MSWin32-x64-multi-thread
    C:/Strawberry/perl/site/lib
    C:/Strawberry/perl/vendor/lib
    C:/Strawberry/perl/lib

@@ report-cpan-reporter-1.2020.txt

This distribution has been tested as part of the CPAN Testers
project, supporting the Perl programming language.  See
http://wiki.cpantesters.org/ for more information or email
questions to cpan-testers-discuss@perl.org


--
Dear Bartosz Jarzyna,

This is a computer-generated report for Bitcoin-Crypto-4.005
on perl 5.43.10, created by CPAN-Reporter-1.2020.

Thank you for uploading your work to CPAN.  Congratulations!
All tests were successful.

Sections of this report:

    * Tester comments
    * Program output
    * Prerequisites
    * Environment and other context

------------------------------
TESTER COMMENTS
------------------------------

Additional comments from tester:

this report is from an automated smoke testing program
and was not reviewed by a human for accuracy

------------------------------
PROGRAM OUTPUT
------------------------------

Output from '/usr/bin/make test':

PERL_DL_NONLAZY=1 "/home/sand/src/perl/repoperls/installed-perls/host/k93msid/v5.43.10/ac75/bin/perl" "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness(0, 'blib/lib', 'blib/arch')" t/*.t t/Key/*.t t/PSBT/*.t t/Script/*.t t/Taproot/*.t t/Transaction/*.t t/Transaction/Signer/*.t
t/author-pod-links.t ...................... skipped: these tests are for testing by the author
t/author-pod-syntax.t ..................... skipped: these tests are for testing by the author
t/Base58.t ................................ ok
t/Bech32.t ................................ ok
t/BIP44.t ................................. ok
t/BIP85.t ................................. ok
t/Block.t ................................. ok
t/blockchain.t ............................ ok
t/Crypto.t ................................ ok
t/DerivationPath.t ........................ ok
t/edge-cases.t ............................ ok
t/Exception.t ............................. ok
t/Helpers.t ............................... ok
t/Key/derivation.t ........................ ok
t/Key/ExtPrivate.t ........................ ok
t/Key/ExtPublic.t ......................... ok
t/Key/NUMS.t .............................. ok
t/Key/Private.t ........................... ok
t/Key/Public.t ............................ ok
t/Network.t ............................... ok
t/predefined-networks.t ................... ok
t/PSBT/basic.t ............................ ok
t/PSBT/bip174-invalid.t ................... ok
t/PSBT/bip174-valid.t ..................... ok
t/PSBT/bip370-invalid.t ................... ok
t/PSBT/bip370-valid.t ..................... ok
t/PSBT/bip371-invalid.t ................... ok
t/PSBT/bip371-valid.t ..................... ok
t/PSBT/dump.t ............................. ok
t/purpose-tracking.t ...................... ok
t/release-script.t ........................ skipped: these tests are for release candidate testing
t/release-taproot.t ....................... skipped: these tests are for release candidate testing
t/release-transaction.t ................... skipped: these tests are for release candidate testing
t/Script.t ................................ ok
t/Script/addresses.t ...................... ok
t/Script/arithmetic.t ..................... ok
t/Script/basic.t .......................... ok
t/Script/edge-cases.t ..................... ok
t/Script/hashes.t ......................... ok
t/Script/logic.t .......................... ok
t/Script/opcode.t ......................... ok
t/Script/reserved.t ....................... ok
t/Script/scripts.t ........................ ok
t/Script/standard-types.t ................. ok
t/Script/step.t ........................... ok
t/Script/Tree.t ........................... ok
t/Taproot/BIP341-key-path-spending.t ...... ok
t/Taproot/BIP341-script-pub-key.t ......... ok
t/Taproot/BIP342-minimalif.t .............. ok
t/Taproot/BIP342-op-success.t ............. ok
t/Taproot/BIP86.t ......................... ok
t/Taproot/derivation.t .................... ok
t/Taproot/learnmeabitcoin.t ............... ok
t/Taproot/live-transactions.t ............. ok
t/Transaction/basic.t ..................... ok
t/Transaction/checkmultisig.t ............. ok
t/Transaction/checksig.t .................. ok
t/Transaction/checksigadd.t ............... ok
t/Transaction/deterministic-signatures.t .. ok
t/Transaction/digest.t .................... ok
t/Transaction/dump.t ...................... ok
t/Transaction/edge-cases.t ................ ok
t/Transaction/flags.t ..................... ok
t/Transaction/locktime.t .................. ok
t/Transaction/sequence.t .................. ok
t/Transaction/sign.t ...................... ok
t/Transaction/Signer/compat.t ............. ok
t/Transaction/Signer/edge-cases.t ......... ok
t/Transaction/Signer/legacy.t ............. ok
t/Transaction/Signer/legacy_multisig.t .... ok
t/Transaction/Signer/segwit.t ............. ok
t/Transaction/Signer/segwit_multisig.t .... ok
t/Transaction/Signer/taproot.t ............ ok
t/Transaction/taproot.t ................... ok
t/Transaction/UTXO.t ...................... ok
t/Types.t ................................. ok
t/Util.t .................................. ok
All tests successful.
Files=77, Tests=715, 80 wallclock secs ( 0.37 usr  0.23 sys + 58.30 cusr  7.25 csys = 66.15 CPU)
Result: PASS

------------------------------
PREREQUISITES
------------------------------

Prerequisite modules loaded:

requires:

    Module               Need     Have     
    -------------------- -------- ---------
    Bitcoin::BIP39       0.002    0.003    
    Bitcoin::Secp256k1   0.011    0.011    
    CryptX               0.074    0.087_007
    Feature::Compat::Try 0        0.05     
    List::Util           1.45     1.70     
    Math::BigInt         1.999831 2.005003 
    Moo                  2.003004 2.005005 
    Mooish::Base         1.005    1.005    
    namespace::autoclean 0        0.31     
    perl                 5.014    5.043010 
    Type::Tiny           2        2.010001 

build_requires:

    Module               Need     Have     
    -------------------- -------- ---------
    ExtUtils::MakeMaker  0        7.78     
    Test2::V0            0.000139 1.302219 

configure_requires:

    Module               Need     Have     
    -------------------- -------- ---------
    ExtUtils::MakeMaker  0        7.78     


------------------------------
ENVIRONMENT AND OTHER CONTEXT
------------------------------

Environment variables:

    AUTOMATED_TESTING = 1
    LANG = en_US.UTF-8
    LANGUAGE = en_US:en
    PATH = /home/sand/bin:/usr/local/bin:/usr/bin:/bin:/usr/games:/usr/local/perl/bin:/usr/X11/bin:/sbin:/usr/sbin
    PERL5LIB = 
    PERL5OPT = 
    PERL5_CPANPLUS_IS_RUNNING = 3987377
    PERL5_CPAN_IS_RUNNING = 3987377
    PERL_CANARY_STABILITY_NOPROMPT = 1
    PERL_MM_USE_DEFAULT = 1
    PERL_USE_UNSAFE_INC = 1
    SHELL = /usr/bin/zsh
    TERM = screen

Perl special variables (and OS-specific diagnostics, for MSWin32):

    $^X = /home/sand/src/perl/repoperls/installed-perls/host/k93msid/v5.43.10/ac75/bin/perl
    $UID/$EUID = 1005 / 1005
    $GID = 1005 1005
    $EGID = 1005 1005

Perl module toolchain versions installed:

    Module              Have    
    ------------------- --------
    CPAN                2.38    
    CPAN::Meta          2.150013
    Cwd                 3.95    
    ExtUtils::CBuilder  0.280243
    ExtUtils::Command   7.78    
    ExtUtils::Install   2.22    
    ExtUtils::MakeMaker 7.78    
    ExtUtils::Manifest  1.75    
    ExtUtils::ParseXS   3.63    
    File::Spec          3.95    
    JSON                4.11    
    JSON::PP            4.18    
    Module::Build       0.4234  
    Module::Signature   0.93    
    Parse::CPAN::Meta   2.150013
    Test2               1.302219
    Test::Harness       3.52    
    Test::More          1.302219
    YAML                1.31    
    YAML::Syck          1.44    
    version             0.9934  


--

Summary of my perl5 (revision 5 version 43 subversion 10) configuration:
  Commit id: 068830eb0bb2c1a602e432b25a91dae1c2ba9239
  Platform:
    osname=linux
    osvers=6.12.38+deb13-amd64
    archname=x86_64-linux-thread-multi-ld
    uname='linux k93msid 6.12.38+deb13-amd64 #1 smp preempt_dynamic debian 6.12.38-1 (2025-07-16) x86_64 gnulinux '
    config_args='-Dprefix=/home/sand/src/perl/repoperls/installed-perls/host/k93msid/v5.43.10/ac75 -Dmyhostname=k93msid -Dinstallusrbinperl=n -Uversiononly -Dusedevel -des -Ui_db -Dlibswanted=cl pthread socket inet nsl gdbm dbm malloc dl ld sun m crypt sec util c cposix posix ucb BSD gdbm_compat -Duseithreads -Duselongdouble -DEBUGGING=both'
    hint=recommended
    useposix=true
    d_sigaction=define
    useithreads=define
    usemultiplicity=define
    use64bitint=define
    use64bitall=define
    uselongdouble=define
    usemymalloc=n
    default_inc_excludes_dot=define
  Compiler:
    cc='cc'
    ccflags ='-D_REENTRANT -D_GNU_SOURCE -fwrapv -DDEBUGGING -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -D_FORTIFY_SOURCE=2'
    optimize='-O2 -g'
    cppflags='-D_REENTRANT -D_GNU_SOURCE -fwrapv -DDEBUGGING -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/local/include'
    ccversion=''
    gccversion='14.3.0'
    gccosandvers=''
    intsize=4
    longsize=8
    ptrsize=8
    doublesize=8
    byteorder=12345678
    doublekind=3
    d_longlong=define
    longlongsize=8
    d_longdbl=define
    longdblsize=16
    longdblkind=3
    ivtype='long'
    ivsize=8
    nvtype='long double'
    nvsize=16
    Off_t='off_t'
    lseeksize=8
    alignbytes=16
    prototype=define
  Linker and Libraries:
    ld='cc'
    ldflags =' -fstack-protector-strong -L/usr/local/lib'
    libpth=/usr/local/lib /usr/lib/x86_64-linux-gnu /usr/lib /usr/lib64
    libs=-lpthread -lnsl -ldl -lm -lcrypt -lutil -lc
    perllibs=-lpthread -lnsl -ldl -lm -lcrypt -lutil -lc
    libc=/lib/x86_64-linux-gnu/libc.so.6
    so=so
    useshrplib=false
    libperl=libperl.a
    gnulibc_version='2.42'
  Dynamic Linking:
    dlsrc=dl_dlopen.xs
    dlext=so
    d_dlsymun=undef
    ccdlflags='-Wl,-E'
    cccdlflags='-fPIC'
    lddlflags='-shared -O2 -g -L/usr/local/lib -fstack-protector-strong'


Characteristics of this binary (from libperl): 
  Compile-time options:
    DEBUGGING
    HAS_LONG_DOUBLE
    HAS_STRTOLD
    HAS_TIMES
    MULTIPLICITY
    PERLIO_LAYERS
    PERL_COPY_ON_WRITE
    PERL_HASH_FUNC_SIPHASH13
    PERL_HASH_USE_SBOX32
    PERL_MALLOC_WRAP
    PERL_OP_PARENT
    PERL_PRESERVE_IVUV
    PERL_TRACK_MEMPOOL
    PERL_USE_DEVEL
    PERL_USE_SAFE_PUTENV
    USE_64_BIT_ALL
    USE_64_BIT_INT
    USE_ITHREADS
    USE_LARGE_FILES
    USE_LOCALE
    USE_LOCALE_COLLATE
    USE_LOCALE_CTYPE
    USE_LOCALE_NUMERIC
    USE_LOCALE_TIME
    USE_LONG_DOUBLE
    USE_PERLIO
    USE_PERL_ATOF
    USE_REENTRANT_API
    USE_THREAD_SAFE_LOCALE
  Built under linux
  Compiled at Apr 20 2026 15:28:39
  %ENV:
    PERL5LIB=""
    PERL5OPT=""
    PERL5_CPANPLUS_IS_RUNNING="3987377"
    PERL5_CPAN_IS_RUNNING="3987377"
    PERL_CANARY_STABILITY_NOPROMPT="1"
    PERL_MM_USE_DEFAULT="1"
    PERL_USE_UNSAFE_INC="1"
  @INC:
    /home/sand/src/perl/repoperls/installed-perls/host/k93msid/v5.43.10/ac75/lib/site_perl/5.43.10/x86_64-linux-thread-multi-ld
    /home/sand/src/perl/repoperls/installed-perls/host/k93msid/v5.43.10/ac75/lib/site_perl/5.43.10
    /home/sand/src/perl/repoperls/installed-perls/host/k93msid/v5.43.10/ac75/lib/5.43.10/x86_64-linux-thread-multi-ld
    /home/sand/src/perl/repoperls/installed-perls/host/k93msid/v5.43.10/ac75/lib/5.43.10
    .

@@ report-cpan-reporter-1.2019-with-test-summary.txt

This distribution has been tested as part of the CPAN Testers
project, supporting the Perl programming language.  See
http://wiki.cpantesters.org/ for more information or email
questions to cpan-testers-discuss@perl.org


--
Dear Nicolas Georges,

This is a computer-generated report for XML-WriterX-Simple-0.151401
on perl 5.41.2, created by CPAN-Reporter-1.2019.

Thank you for uploading your work to CPAN.  Congratulations!
All tests were successful.

Sections of this report:

    * Tester comments
    * Program output
    * Prerequisites
    * Environment and other context

------------------------------
TESTER COMMENTS
------------------------------

Additional comments from tester:

this report is from an automated smoke testing program
and was not reviewed by a human for accuracy

------------------------------
PROGRAM OUTPUT
------------------------------

Output from '/usr/bin/make test':

PERL_DL_NONLAZY=1 "/usr/home/cpan/bin/perl/bin/perl5.41.2" "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness(0, 'blib/lib', 'blib/arch')" t/*.t
# Testing XML::WriterX::Simple 0.151401, Perl 5.041002, /usr/home/cpan/bin/perl/bin/perl5.41.2
t/00-load.t ............... ok
t/10-produce.t ............ ok
t/boilerplate.t ........... ok
t/manifest.t .............. skipped: Author tests not required for installation
t/pod-coverage.t .......... ok
t/pod.t ................... ok
t/release-pod-coverage.t .. skipped: these tests are for release candidate testing
t/release-pod-syntax.t .... skipped: these tests are for release candidate testing
All tests successful.

Test Summary Report
-------------------
t/boilerplate.t         (Wstat: 0 Tests: 3 Failed: 0)
  TODO passed:   1, 3
Files=8, Tests=18,  0 wallclock secs ( 0.03 usr  0.02 sys +  0.33 cusr  0.04 csys =  0.41 CPU)
Result: PASS

------------------------------
PREREQUISITES
------------------------------

Prerequisite modules loaded:

requires:

    Module              Need  Have    
    ------------------- ----- --------
    perl                5.010 5.041002
    strict              0     1.13    
    warnings            0     1.70    
    XML::Writer         0     0.900   

build_requires:

    Module              Need  Have    
    ------------------- ----- --------
    ExtUtils::MakeMaker 0     7.70    
    Test::More          0     1.302199

configure_requires:

    Module              Need  Have    
    ------------------- ----- --------
    ExtUtils::MakeMaker 0     7.70    


------------------------------
ENVIRONMENT AND OTHER CONTEXT
------------------------------

Environment variables:

    AUTOMATED_TESTING = 1
    DATE_MANIP_TEST_DM5 = 1
    LC_ALL = C
    NONINTERACTIVE_TESTING = 1
    NO_NETWORK_TESTING = 1
    PATH = /home/cpan/bin/perl/bin:/home/cpan/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/games:/usr/local/sbin:/usr/local/bin:/home/cpan/bin
    PERL5LIB = 
    PERL5OPT = 
    PERL5_CPANPLUS_IS_RUNNING = 22479
    PERL5_CPAN_IS_RUNNING = 22479
    PERL_MM_USE_DEFAULT = 1
    PERL_USE_UNSAFE_INC = 1
    SHELL = /usr/local/bin/bash
    TERM = screen
    TMPDIR = /home/cpan/tmp

Perl special variables (and OS-specific diagnostics, for MSWin32):

    $^X = /usr/home/cpan/bin/perl/bin/perl5.41.2
    $UID/$EUID = 1002 / 1002
    $GID = 1002 1002
    $EGID = 1002 1002

Perl module toolchain versions installed:

    Module              Have    
    ------------------- --------
    CPAN                2.36    
    CPAN::Meta          2.150010
    Cwd                 3.90    
    ExtUtils::CBuilder  0.280240
    ExtUtils::Command   7.70    
    ExtUtils::Install   2.22    
    ExtUtils::MakeMaker 7.70    
    ExtUtils::Manifest  1.75    
    ExtUtils::ParseXS   3.52    
    File::Spec          3.90    
    JSON                4.10    
    JSON::PP            4.16    
    Module::Build       0.4234  
    Module::Signature   0.88    
    Parse::CPAN::Meta   2.150010
    Test2               1.302199
    Test::Harness       3.48    
    Test::More          1.302199
    YAML                1.31    
    YAML::Syck          1.34    
    version             0.9932  


--

Summary of my perl5 (revision 5 version 41 subversion 2) configuration:
  Commit id: b786e5e6e5e961082d2f48dac2a1f3ab69339b14
  Platform:
    osname=midnightbsd
    osvers=3.1.3
    archname=amd64-midnightbsd
    uname='midnightbsd cjg-midnightbsd3 3.1.3 midnightbsd 3.1.3 #9n12826-9619ab86ba(stable3.1)-dirty: mon dec 25 14:57:58 est 2023 root@m3164:usrobjusrsrcamd64.amd64sysgeneric amd64 '
    config_args='-des -Dprefix=/home/cpan/bin/perl -Dscriptdir=/home/cpan/bin/perl/bin -Dusedevel -Duse64bitall'
    hint=recommended
    useposix=true
    d_sigaction=define
    useithreads=undef
    usemultiplicity=undef
    use64bitint=define
    use64bitall=define
    uselongdouble=undef
    usemymalloc=n
    default_inc_excludes_dot=define
  Compiler:
    cc='cc'
    ccflags ='-DHAS_FPSETMASK -DHAS_FLOATINGPOINT_H -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/local/include'
    optimize='-O'
    cppflags='-DHAS_FPSETMASK -DHAS_FLOATINGPOINT_H -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/local/include'
    ccversion=''
    gccversion='MidnightBSD Clang 13.0.0 (git@github.com:llvm/llvm-project.git llvmorg-13.0.0-0-gd7b669b3a303)'
    gccosandvers=''
    intsize=4
    longsize=8
    ptrsize=8
    doublesize=8
    byteorder=12345678
    doublekind=3
    d_longlong=define
    longlongsize=8
    d_longdbl=define
    longdblsize=16
    longdblkind=3
    ivtype='long'
    ivsize=8
    nvtype='double'
    nvsize=8
    Off_t='off_t'
    lseeksize=8
    alignbytes=8
    prototype=define
  Linker and Libraries:
    ld='cc'
    ldflags ='-Wl,-E  -fstack-protector-strong -L/usr/local/lib'
    libpth=/usr/lib /usr/local/lib /usr/lib/clang/13.0.0/lib
    libs=-lpthread -lgdbm -ldl -lm -lcrypt -lutil -lc
    perllibs=-lpthread -ldl -lm -lcrypt -lutil -lc
    libc=
    so=so
    useshrplib=false
    libperl=libperl.a
    gnulibc_version=''
  Dynamic Linking:
    dlsrc=dl_dlopen.xs
    dlext=so
    d_dlsymun=undef
    ccdlflags=' '
    cccdlflags='-DPIC -fPIC'
    lddlflags='-shared  -L/usr/local/lib -fstack-protector-strong'


Characteristics of this binary (from libperl): 
  Compile-time options:
    HAS_LONG_DOUBLE
    HAS_STRTOLD
    HAS_TIMES
    PERLIO_LAYERS
    PERL_COPY_ON_WRITE
    PERL_DONT_CREATE_GVSV
    PERL_HASH_FUNC_SIPHASH13
    PERL_HASH_USE_SBOX32
    PERL_MALLOC_WRAP
    PERL_OP_PARENT
    PERL_PRESERVE_IVUV
    PERL_USE_DEVEL
    PERL_USE_SAFE_PUTENV
    USE_64_BIT_ALL
    USE_64_BIT_INT
    USE_LARGE_FILES
    USE_LOCALE
    USE_LOCALE_COLLATE
    USE_LOCALE_CTYPE
    USE_LOCALE_NUMERIC
    USE_LOCALE_TIME
    USE_PERLIO
    USE_PERL_ATOF
  Built under midnightbsd
  Compiled at Jul  8 2024 00:47:29
  %ENV:
    PERL5LIB=""
    PERL5OPT=""
    PERL5_CPANPLUS_IS_RUNNING="22479"
    PERL5_CPAN_IS_RUNNING="22479"
    PERL_MM_USE_DEFAULT="1"
    PERL_USE_UNSAFE_INC="1"
  @INC:
    /home/cpan/bin/perl/lib/site_perl/5.41.2/amd64-midnightbsd
    /home/cpan/bin/perl/lib/site_perl/5.41.2
    /home/cpan/bin/perl/lib/5.41.2/amd64-midnightbsd
    /home/cpan/bin/perl/lib/5.41.2
    .

@@ prerequisites-cpanminus-reporter-0.18-not-found.txt
Prerequisite modules loaded:

    No requirements found

@@ prerequisites-cpanplus-0.9178.txt

Here is a list of prerequisites you specified and versions we
managed to load:

	  Module Name                        Have     Want
	  Data::Sah::Util::Type              0.46     0.45
	  Exporter                           5.72     5.57
	  ExtUtils::MakeMaker                7.36        0
	  File::Spec                         3.75        0
	  Gen::Test::Rinci::FuncResult       0.06        0
	  IO::Handle                         1.36        0
	  IPC::Open3                         1.20        0
	  JSON                               4.02        0
	  Test::More                     1.302164     0.98
	  strict                             1.11        0
	  warnings                           1.36        0

Perl module toolchain versions installed:
	Module Name                        Have
	CPANPLUS                         0.9178
	CPANPLUS::Dist::Build              0.90
	Cwd                                3.75
	ExtUtils::CBuilder             0.280231
	ExtUtils::Command                  7.36
	ExtUtils::Install                  2.14
	ExtUtils::MakeMaker                7.36
	ExtUtils::Manifest                 1.72
	ExtUtils::ParseXS                  3.35
	File::Spec                         3.75
	Module::Build                    0.4229
	Pod::Parser                        1.63
	Pod::Simple                        3.32
	Test2                          1.302164
	Test::Harness                      3.42
	Test::More                     1.302164
	version                          0.9924

******************************** NOTE ********************************
The comments above are created mechanically, possibly without manual
checking by the sender.  As there are many people performing automatic
tests on each upload to CPAN, it is likely that you will receive
identical messages about the same problem.

If you believe that the message is mistaken, please reply to the first
one with correction and/or additional informations, and do not take
it personally.  We appreciate your patience. :)
**********************************************************************

Additional comments:


This report was machine-generated by CPANPLUS::Dist::YACSmoke 1.08.
Powered by minismokebox version 0.68

CPANPLUS is prefering Build.PL

@@ prerequisites-cpan-reporter-1.2020.txt
Prerequisite modules loaded:

requires:

    Module               Need     Have     
    -------------------- -------- ---------
    Bitcoin::BIP39       0.002    0.003    
    Bitcoin::Secp256k1   0.011    0.011    
    CryptX               0.074    0.087_007
    Feature::Compat::Try 0        0.05     
    List::Util           1.45     1.70     
    Math::BigInt         1.999831 2.005003 
    Moo                  2.003004 2.005005 
    Mooish::Base         1.005    1.005    
    namespace::autoclean 0        0.31     
    perl                 5.014    5.043010 
    Type::Tiny           2        2.010001 

build_requires:

    Module               Need     Have     
    -------------------- -------- ---------
    ExtUtils::MakeMaker  0        7.78     
    Test2::V0            0.000139 1.302219 

configure_requires:

    Module               Need     Have     
    -------------------- -------- ---------
    ExtUtils::MakeMaker  0        7.78     

@@ environment-cpan-reporter-1.2020.txt

Environment variables:

    AUTOMATED_TESTING = 1
    LANG = en_US.UTF-8
    LANGUAGE = en_US:en
    PATH = /home/sand/bin:/usr/local/bin:/usr/bin:/bin:/usr/games:/usr/local/perl/bin:/usr/X11/bin:/sbin:/usr/sbin
    PERL5LIB = 
    PERL5OPT = 
    PERL5_CPANPLUS_IS_RUNNING = 3987377
    PERL5_CPAN_IS_RUNNING = 3987377
    PERL_CANARY_STABILITY_NOPROMPT = 1
    PERL_MM_USE_DEFAULT = 1
    PERL_USE_UNSAFE_INC = 1
    SHELL = /usr/bin/zsh
    TERM = screen

Perl special variables (and OS-specific diagnostics, for MSWin32):

    $^X = /home/sand/src/perl/repoperls/installed-perls/host/k93msid/v5.43.10/ac75/bin/perl
    $UID/$EUID = 1005 / 1005
    $GID = 1005 1005
    $EGID = 1005 1005

Perl module toolchain versions installed:

    Module              Have    
    ------------------- --------
    CPAN                2.38    
    CPAN::Meta          2.150013
    Cwd                 3.95    
    ExtUtils::CBuilder  0.280243
    ExtUtils::Command   7.78    
    ExtUtils::Install   2.22    
    ExtUtils::MakeMaker 7.78    
    ExtUtils::Manifest  1.75    
    ExtUtils::ParseXS   3.63    
    File::Spec          3.95    
    JSON                4.11    
    JSON::PP            4.18    
    Module::Build       0.4234  
    Module::Signature   0.93    
    Parse::CPAN::Meta   2.150013
    Test2               1.302219
    Test::Harness       3.52    
    Test::More          1.302219
    YAML                1.31    
    YAML::Syck          1.44    
    version             0.9934  

@@ report-cpanplus-0.9178.txt

This distribution has been tested as part of the CPAN Testers
project, supporting the Perl programming language.  See
http://wiki.cpantesters.org/ for more information or email
questions to cpan-testers-discuss@perl.org


--

Dear perlancar,

This is a computer-generated error report created automatically by
CPANPLUS, version 0.9178. Testers personal comments may appear
at the end of this report.


Thank you for uploading your work to CPAN.  Congratulations!
All tests were successful.

TEST RESULTS:

Below is the error stack from stage 'make test':

PERL_DL_NONLAZY=1 "/home/cpan/pit/bare/perl-5.24.0/bin/perl" "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness(0, 'blib/lib', 'blib/arch')" t/*.t
t/00-compile.t ........... ok
t/01-basics.t ............ ok
t/author-critic.t ........ skipped: these tests are for testing by the author
t/author-pod-coverage.t .. skipped: these tests are for testing by the author
t/author-pod-syntax.t .... skipped: these tests are for testing by the author
t/release-rinci.t ........ skipped: these tests are for release candidate testing
All tests successful.
Files=6, Tests=8,  0 wallclock secs ( 0.04 usr  0.00 sys +  0.26 cusr  0.14 csys =  0.44 CPU)
Result: PASS


PREREQUISITES:

Here is a list of prerequisites you specified and versions we
managed to load:

	  Module Name                        Have     Want
	  Data::Sah::Util::Type              0.46     0.45
	  Exporter                           5.72     5.57
	  ExtUtils::MakeMaker                7.36        0
	  File::Spec                         3.75        0
	  Gen::Test::Rinci::FuncResult       0.06        0
	  IO::Handle                         1.36        0
	  IPC::Open3                         1.20        0
	  JSON                               4.02        0
	  Test::More                     1.302164     0.98
	  strict                             1.11        0
	  warnings                           1.36        0

Perl module toolchain versions installed:
	Module Name                        Have
	CPANPLUS                         0.9178
	CPANPLUS::Dist::Build              0.90
	Cwd                                3.75
	ExtUtils::CBuilder             0.280231
	ExtUtils::Command                  7.36
	ExtUtils::Install                  2.14
	ExtUtils::MakeMaker                7.36
	ExtUtils::Manifest                 1.72
	ExtUtils::ParseXS                  3.35
	File::Spec                         3.75
	Module::Build                    0.4229
	Pod::Parser                        1.63
	Pod::Simple                        3.32
	Test2                          1.302164
	Test::Harness                      3.42
	Test::More                     1.302164
	version                          0.9924

******************************** NOTE ********************************
The comments above are created mechanically, possibly without manual
checking by the sender.  As there are many people performing automatic
tests on each upload to CPAN, it is likely that you will receive
identical messages about the same problem.

If you believe that the message is mistaken, please reply to the first
one with correction and/or additional informations, and do not take
it personally.  We appreciate your patience. :)
**********************************************************************

Additional comments:


This report was machine-generated by CPANPLUS::Dist::YACSmoke 1.08.
Powered by minismokebox version 0.68

CPANPLUS is prefering Build.PL

------------------------------
ENVIRONMENT AND OTHER CONTEXT
------------------------------

Environment variables:

    AUTOMATED_TESTING = 1
    NONINTERACTIVE_TESTING = 1
    PATH = /home/cpan/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/X11R7/bin:/usr/pkg/bin:/usr/pkg/sbin:/usr/games:/usr/local/bin:/usr/local/sbin
    PERL5LIB = /home/cpan/pit/jail/SAgvDEX319/lib/perl5:/home/cpan/pit/bare/conf/perl-5.24.0/.cpanplus/5.24.0/build/L2nQg6Us0Q/Perinci-Sub-ConvertArgs-Argv-0.110/blib/lib:/home/cpan/pit/bare/conf/perl-5.24.0/.cpanplus/5.24.0/build/L2nQg6Us0Q/Perinci-Sub-ConvertArgs-Argv-0.110/blib/arch
    PERL5_CPANPLUS_IS_RUNNING = 27449
    PERL5_CPANPLUS_IS_VERSION = 0.9178
    PERL5_MINISMOKEBOX = 0.68
    PERL5_YACSMOKE_BASE = /home/cpan/pit/bare/conf/perl-5.24.0
    PERL_EXTUTILS_AUTOINSTALL = --defaultdeps
    PERL_LOCAL_LIB_ROOT = /home/cpan/pit/jail/SAgvDEX319
    PERL_MB_OPT = --install_base "/home/cpan/pit/jail/SAgvDEX319"
    PERL_MM_OPT = INSTALL_BASE=/home/cpan/pit/jail/SAgvDEX319
    PERL_MM_USE_DEFAULT = 1
    PERL_USE_UNSAFE_INC = 1
    SHELL = /usr/pkg/bin/bash
    TERM = screen

Perl special variables (and OS-specific diagnostics, for MSWin32):

    Perl: $^X = /home/cpan/pit/bare/perl-5.24.0/bin/perl
    UID:  $<  = 1001
    EUID: $>  = 1001
    GID:  $(  = 100 100
    EGID: $)  = 100 100


-------------------------------


--

Summary of my perl5 (revision 5 version 24 subversion 0) configuration:
   
  Platform:
    osname=netbsd, osvers=8.1, archname=i386-netbsd
    uname='netbsd naboo.bingosnet.co.uk 8.1 netbsd 8.1 (generic) #0: fri may 31 08:43:59 utc 2019 mkrepro@mkrepro.netbsd.org:usrsrcsysarchi386compilegeneric i386 '
    config_args='-des -Dprefix=/home/cpan/pit/bare/perl-5.24.0'
    hint=recommended, useposix=true, d_sigaction=define
    useithreads=undef, usemultiplicity=undef
    use64bitint=undef, use64bitall=undef, uselongdouble=undef
    usemymalloc=n, bincompat5005=undef
  Compiler:
    cc='cc', ccflags ='-fwrapv -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/pkg/include -D_FORTIFY_SOURCE=2',
    optimize='-O',
    cppflags='-fwrapv -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/pkg/include'
    ccversion='', gccversion='5.5.0', gccosandvers=''
    intsize=4, longsize=4, ptrsize=4, doublesize=8, byteorder=1234, doublekind=3
    d_longlong=define, longlongsize=8, d_longdbl=define, longdblsize=12, longdblkind=3
    ivtype='long', ivsize=4, nvtype='double', nvsize=8, Off_t='off_t', lseeksize=8
    alignbytes=4, prototype=define
  Linker and Libraries:
    ld='cc', ldflags =' -Wl,-rpath,/usr/pkg/lib -Wl,-rpath,/usr/local/lib -fstack-protector-strong -L/usr/pkg/lib'
    libpth=/usr/include/gcc-5 /usr/lib /usr/pkg/lib /lib
    libs=-lpthread -lgdbm -lm -lcrypt -lutil -lc -lposix
    perllibs=-lpthread -lm -lcrypt -lutil -lc -lposix
    libc=/lib/libc.so, so=so, useshrplib=false, libperl=libperl.a
    gnulibc_version=''
  Dynamic Linking:
    dlsrc=dl_dlopen.xs, dlext=so, d_dlsymun=undef, ccdlflags='-Wl,-E '
    cccdlflags='-DPIC -fPIC ', lddlflags='-shared  -L/usr/pkg/lib -fstack-protector-strong'


Characteristics of this binary (from libperl): 
  Compile-time options: HAS_TIMES PERLIO_LAYERS PERL_COPY_ON_WRITE
                        PERL_DONT_CREATE_GVSV
                        PERL_HASH_FUNC_ONE_AT_A_TIME_HARD PERL_MALLOC_WRAP
                        PERL_PRESERVE_IVUV USE_LARGE_FILES USE_LOCALE
                        USE_LOCALE_COLLATE USE_LOCALE_CTYPE
                        USE_LOCALE_NUMERIC USE_LOCALE_TIME USE_PERLIO
                        USE_PERL_ATOF
  Locally applied patches:
	Devel::PatchPerl 1.64
  Built under netbsd
  Compiled at Aug  3 2019 04:39:00
  %ENV:
    PERL5LIB="/home/cpan/pit/jail/SAgvDEX319/lib/perl5:/home/cpan/pit/bare/conf/perl-5.24.0/.cpanplus/5.24.0/build/L2nQg6Us0Q/Perinci-Sub-ConvertArgs-Argv-0.110/blib/lib:/home/cpan/pit/bare/conf/perl-5.24.0/.cpanplus/5.24.0/build/L2nQg6Us0Q/Perinci-Sub-ConvertArgs-Argv-0.110/blib/arch"
    PERL5_CPANPLUS_IS_RUNNING="27449"
    PERL5_CPANPLUS_IS_VERSION="0.9178"
    PERL5_MINISMOKEBOX="0.68"
    PERL5_YACSMOKE_BASE="/home/cpan/pit/bare/conf/perl-5.24.0"
    PERL_EXTUTILS_AUTOINSTALL="--defaultdeps"
    PERL_LOCAL_LIB_ROOT="/home/cpan/pit/jail/SAgvDEX319"
    PERL_MB_OPT="--install_base "/home/cpan/pit/jail/SAgvDEX319""
    PERL_MM_OPT="INSTALL_BASE=/home/cpan/pit/jail/SAgvDEX319"
    PERL_MM_USE_DEFAULT="1"
    PERL_USE_UNSAFE_INC="1"
  @INC:
    /home/cpan/pit/jail/SAgvDEX319/lib/perl5/5.24.0/i386-netbsd
    /home/cpan/pit/jail/SAgvDEX319/lib/perl5/5.24.0
    /home/cpan/pit/jail/SAgvDEX319/lib/perl5/i386-netbsd
    /home/cpan/pit/jail/SAgvDEX319/lib/perl5
    /home/cpan/pit/bare/conf/perl-5.24.0/.cpanplus/5.24.0/build/L2nQg6Us0Q/Perinci-Sub-ConvertArgs-Argv-0.110/blib/lib
    /home/cpan/pit/bare/conf/perl-5.24.0/.cpanplus/5.24.0/build/L2nQg6Us0Q/Perinci-Sub-ConvertArgs-Argv-0.110/blib/arch
    /home/cpan/pit/bare/perl-5.24.0/lib/site_perl/5.24.0/i386-netbsd
    /home/cpan/pit/bare/perl-5.24.0/lib/site_perl/5.24.0
    /home/cpan/pit/bare/perl-5.24.0/lib/5.24.0/i386-netbsd
    /home/cpan/pit/bare/perl-5.24.0/lib/5.24.0
    .

@@ report-cpanminus-reporter-0.12-with-report-prereqs.txt

This distribution has been tested as part of the CPAN Testers
project, supporting the Perl programming language.  See
http://wiki.cpantesters.org/ for more information or email
questions to cpan-testers-discuss@perl.org


--
Dear RJBS,

This is a computer-generated report for Throwable-0.200013
on perl 5.16.3, created by App::cpanminus::reporter 0.12 (1.7027).

Thank you for uploading your work to CPAN.  Congratulations!
All tests were successful.

Sections of this report:

    * Tester comments
    * Program output
    * Prerequisites
    * Environment and other context

------------------------------
TESTER COMMENTS
------------------------------

Additional comments from tester:

none provided

------------------------------
PROGRAM OUTPUT
------------------------------

Output from '':

Building and testing Throwable-0.200013
cp lib/Throwable.pm blib/lib/Throwable.pm
cp lib/StackTrace/Auto.pm blib/lib/StackTrace/Auto.pm
cp lib/Throwable/Error.pm blib/lib/Throwable/Error.pm
Manifying 3 pod documents
PERL_DL_NONLAZY=1 "/home/mojolicious/perl5/perlbrew/perls/perl-5.16.3/bin/perl" "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness(0, 'blib/lib', 'blib/arch')" t/*.t
# 
# Versions for all modules listed in static metadata (including optional ones):
# 
# === Configure Requires ===
# 
#     Module              Want Have
#     ------------------- ---- ----
#     ExtUtils::MakeMaker  any 7.04
# 
# === Test Requires ===
# 
#     Module              Want     Have
#     ------------------- ---- --------
#     Devel::StackTrace   1.32     2.00
#     ExtUtils::MakeMaker  any     7.04
#     File::Spec           any     3.47
#     Test::More          0.96 1.001014
#     base                 any     2.18
#     strict               any     1.07
#     warnings             any     1.13
# 
# === Test Recommends ===
# 
#     Module         Want     Have
#     ---------- -------- --------
#     CPAN::Meta 2.120900 2.120630
# 
# === Runtime Requires ===
# 
#     Module                Want     Have
#     ----------------- -------- --------
#     Carp                   any     1.26
#     Devel::StackTrace     1.32     2.00
#     Module::Runtime      0.002    0.014
#     Moo               1.000001 2.000001
#     Moo::Role              any 2.000001
#     Scalar::Util           any     1.25
#     Sub::Quote             any 2.000001
#     overload               any     1.18
# 
t/00-report-prereqs.t .. ok
t/basic.t .............. ok
All tests successful.
Files=2, Tests=31,  0 wallclock secs ( 0.02 usr  0.00 sys +  0.18 cusr  0.02 csys =  0.22 CPU)
Result: PASS

------------------------------
PREREQUISITES
------------------------------

Prerequisite modules loaded:

runtime:

    Module              Need     Have   
    ------------------- -------- -------
    Carp                0        1.26   
  ! Devel::StackTrace   1.32     n/a    
  ! Module::Runtime     0.002    n/a    
  ! Moo                 1.000001 n/a    
  ! Moo::Role           0        n/a    
    overload            0        1.18   
    Scalar::Util        0        1.25   
  ! Sub::Quote          0        n/a    

configure:

    Module              Need     Have   
    ------------------- -------- -------
    ExtUtils::MakeMaker 0        6.63_02


------------------------------
ENVIRONMENT AND OTHER CONTEXT
------------------------------

Environment variables:

    PATH = /home/mojolicious/perl5/perlbrew/bin:/home/mojolicious/perl5/perlbrew/perls/perl-5.20.1/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/home/mojolicious/mojolib/5.16.3/6.06/bin
    PERLBREW_BASHRC_VERSION = 0.73
    PERLBREW_HOME = /home/mojolicious/.perlbrew
    PERLBREW_MANPATH = /home/mojolicious/perl5/perlbrew/perls/perl-5.20.1/man
    PERLBREW_PATH = /home/mojolicious/perl5/perlbrew/bin:/home/mojolicious/perl5/perlbrew/perls/perl-5.20.1/bin
    PERLBREW_PERL = perl-5.20.1
    PERLBREW_ROOT = /home/mojolicious/perl5/perlbrew
    PERLBREW_VERSION = 0.73
    SHELL = /bin/bash
    TERM = xterm

Perl special variables (and OS-specific diagnostics, for MSWin32):

    EGID = 1003 1003
    EUID = 1003
    EXECUTABLE_NAME = /home/mojolicious/perl5/perlbrew/perls/perl-5.16.3/bin/perl
    GID = 1003 1003
    UID = 1003

Perl module toolchain versions installed:

    Module              Have    
    ------------------- --------
    CPAN                1.9800  
    CPAN::Meta          2.120630
    Cwd                 3.39_02 
    ExtUtils::CBuilder  0.280206
    ExtUtils::Command   1.17    
    ExtUtils::Install   1.58    
    ExtUtils::MakeMaker 6.63_02 
    ExtUtils::Manifest  1.61    
    ExtUtils::ParseXS   3.16    
    File::Spec          3.39_02 
    JSON                2.90    
    JSON::PP            2.27200 
    Module::Build       0.39_01 
    Module::Signature   n/a     
    Parse::CPAN::Meta   1.4402  
    Test::Harness       3.23    
    Test::More          1.001014
    YAML                n/a     
    YAML::Syck          n/a     
    version             0.99    


--

Summary of my perl5 (revision 5 version 16 subversion 3) configuration:
   
  Platform:
    osname=linux, osvers=3.13.0-042stab094.8, archname=x86_64-linux
    uname='linux lvps92-51-161-142.dedicated.hosteurope.de 3.13.0-042stab094.8 #1 smp tue dec 16 20:36:56 msk 2014 x86_64 x86_64 x86_64 gnulinux '
    config_args='-de -Dprefix=/home/mojolicious/perl5/perlbrew/perls/perl-5.16.3 -Aeval:scriptdir=/home/mojolicious/perl5/perlbrew/perls/perl-5.16.3/bin'
    hint=recommended, useposix=true, d_sigaction=define
    useithreads=undef, usemultiplicity=undef
    useperlio=define, d_sfio=undef, uselargefiles=define, usesocks=undef
    use64bitint=define, use64bitall=define, uselongdouble=undef
    usemymalloc=n, bincompat5005=undef
  Compiler:
    cc='cc', ccflags ='-fno-strict-aliasing -pipe -fstack-protector -I/usr/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64',
    optimize='-O2',
    cppflags='-fno-strict-aliasing -pipe -fstack-protector -I/usr/local/include'
    ccversion='', gccversion='4.8.2', gccosandvers=''
    intsize=4, longsize=8, ptrsize=8, doublesize=8, byteorder=12345678
    d_longlong=define, longlongsize=8, d_longdbl=define, longdblsize=16
    ivtype='long', ivsize=8, nvtype='double', nvsize=8, Off_t='off_t', lseeksize=8
    alignbytes=8, prototype=define
  Linker and Libraries:
    ld='cc', ldflags =' -fstack-protector -L/usr/local/lib'
    libpth=/usr/local/lib /lib/x86_64-linux-gnu /lib/../lib /usr/lib/x86_64-linux-gnu /usr/lib/../lib /lib /usr/lib
    libs=-lnsl -ldl -lm -lcrypt -lutil -lc
    perllibs=-lnsl -ldl -lm -lcrypt -lutil -lc
    libc=libc-2.19.so, so=so, useshrplib=false, libperl=libperl.a
    gnulibc_version='2.19'
  Dynamic Linking:
    dlsrc=dl_dlopen.xs, dlext=so, d_dlsymun=undef, ccdlflags='-Wl,-E'
    cccdlflags='-fPIC', lddlflags='-shared -O2 -L/usr/local/lib -fstack-protector'


Characteristics of this binary (from libperl): 
  Compile-time options: HAS_TIMES PERLIO_LAYERS PERL_DONT_CREATE_GVSV
                        PERL_MALLOC_WRAP PERL_PRESERVE_IVUV USE_64_BIT_ALL
                        USE_64_BIT_INT USE_LARGE_FILES USE_LOCALE
                        USE_LOCALE_COLLATE USE_LOCALE_CTYPE
                        USE_LOCALE_NUMERIC USE_PERLIO USE_PERL_ATOF
  Locally applied patches:
	Devel::PatchPerl 1.30
  Built under linux
  Compiled at Feb 14 2015 11:53:05
  %ENV:
    PERLBREW_BASHRC_VERSION="0.73"
    PERLBREW_HOME="/home/mojolicious/.perlbrew"
    PERLBREW_MANPATH="/home/mojolicious/perl5/perlbrew/perls/perl-5.20.1/man"
    PERLBREW_PATH="/home/mojolicious/perl5/perlbrew/bin:/home/mojolicious/perl5/perlbrew/perls/perl-5.20.1/bin"
    PERLBREW_PERL="perl-5.20.1"
    PERLBREW_ROOT="/home/mojolicious/perl5/perlbrew"
    PERLBREW_VERSION="0.73"
  @INC:
    /home/mojolicious/perl5/perlbrew/perls/perl-5.16.3/lib/site_perl/5.16.3/x86_64-linux
    /home/mojolicious/perl5/perlbrew/perls/perl-5.16.3/lib/site_perl/5.16.3
    /home/mojolicious/perl5/perlbrew/perls/perl-5.16.3/lib/5.16.3/x86_64-linux
    /home/mojolicious/perl5/perlbrew/perls/perl-5.16.3/lib/5.16.3
    .

@@ prerequisites-report-prereqs-test.txt
# Versions for all modules listed in static metadata (including optional ones):
# 
# === Configure Requires ===
# 
#     Module              Want Have
#     ------------------- ---- ----
#     ExtUtils::MakeMaker  any 7.04
# 
# === Test Requires ===
# 
#     Module              Want     Have
#     ------------------- ---- --------
#     Devel::StackTrace   1.32     2.00
#     ExtUtils::MakeMaker  any     7.04
#     File::Spec           any     3.47
#     Test::More          0.96 1.001014
#     base                 any     2.18
#     strict               any     1.07
#     warnings             any     1.13
# 
# === Test Recommends ===
# 
#     Module         Want     Have
#     ---------- -------- --------
#     CPAN::Meta 2.120900 2.120630
# 
# === Runtime Requires ===
# 
#     Module                Want     Have
#     ----------------- -------- --------
#     Carp                   any     1.26
#     Devel::StackTrace     1.32     2.00
#     Module::Runtime      0.002    0.014
#     Moo               1.000001 2.000001
#     Moo::Role              any 2.000001
#     Scalar::Util           any     1.25
#     Sub::Quote             any 2.000001
#     overload               any     1.18
# 

@@ prerequisites-cpanminus-reporter-0.12-with-missing.txt

Prerequisite modules loaded:

runtime:

    Module              Need     Have   
    ------------------- -------- -------
    Carp                0        1.26   
  ! Devel::StackTrace   1.32     n/a    
  ! Module::Runtime     0.002    n/a    
  ! Moo                 1.000001 n/a    
  ! Moo::Role           0        n/a    
    overload            0        1.18   
    Scalar::Util        0        1.25   
  ! Sub::Quote          0        n/a    

configure:

    Module              Need     Have   
    ------------------- -------- -------
    ExtUtils::MakeMaker 0        6.63_02


