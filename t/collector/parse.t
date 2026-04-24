
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

  subtest 'CPANPLUS-0.9908' => sub {
    my $report = {
      result => {
        output => {
          uncategorized => data_section('main', 'report-cpanplus-0.9908.txt'),
        },
      },
    };
    my $output = CPAN::Testers::Collector::Parse->parse($report);
    like $output->{distribution}{prerequisites}, subset {
      item {
        phase => 'requires',
        name => 'CGI::Simple::Cookie',
        need => '1.109',
        have => '1.25',
      };
      item {
        phase => 'requires',
        name => 'MooseX::MethodAttributes::Role::AttrContainer::Inheritable',
        have => '0.32',
        need => '0.24',
      };
    }, 'prerequisites' or diag Dumper $output;
    like $output->{environment}{system}{variables}, hash {
      field AUTOMATED_TESTING => "1";
      etc();
    }, 'environment variables' or diag Dumper $report;
    like $output->{environment}{language}{variables}, hash {
      field '$GID' => "1001 1001";
      etc();
    }, 'language special variables' or diag Dumper $report;
    like $output->{environment}{system}{toolchain}, hash {
      field 'Test::More' => "1.302181";
      etc();
    }, 'toolchain modules' or diag Dumper $report;
  };

  subtest 'CPANPLUS-0.9908 with YATH' => sub {
    my $report = {
      result => {
        output => {
          uncategorized => data_section('main', 'report-cpanplus-0.9908-with-yath.txt'),
        },
      },
    };
    my $output = CPAN::Testers::Collector::Parse->parse($report);
    like $output->{distribution}{prerequisites}, subset {
      item {
        phase => 'requires',
        name => 'Carp',
        need => '0',
        have => '1.50',
      };
    }, 'prerequisites' or diag Dumper $output;
    like $output->{environment}{system}{variables}, hash {
      field AUTOMATED_TESTING => "1";
      etc();
    }, 'environment variables' or diag Dumper $report;
    like $output->{environment}{language}{variables}, hash {
      field '$GID' => "1001 1001";
      etc();
    }, 'language special variables' or diag Dumper $report;
    like $output->{environment}{system}{toolchain}, hash {
      field 'Test::More' => "1.302181";
      etc();
    }, 'toolchain modules' or diag Dumper $report;
  };

  subtest 'CPANPLUS-0.9113' => sub {
    my $report = {
      result => {
        output => {
          uncategorized => data_section('main', 'report-cpanplus-0.9113.txt'),
        },
      },
    };
    my $output = CPAN::Testers::Collector::Parse->parse($report);
    like $output->{distribution}{prerequisites}, subset {
      item {
        phase => 'requires',
        name => 'Carp',
        need => '0',
        have => '1.16',
      };
    }, 'prerequisites' or diag Dumper $output;
    like $output->{environment}{system}{variables}, hash {
      field AUTOMATED_TESTING => "1";
      etc();
    }, 'environment variables' or diag Dumper $report;
    like $output->{environment}{language}{variables}, hash {
      field '$GID' => "1001 1001";
      etc();
    }, 'language special variables' or diag Dumper $report;
    like $output->{environment}{system}{toolchain}, hash {
      field 'Test::More' => "0.98";
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


@@ report-cpanplus-0.9908.txt

This distribution has been tested as part of the CPAN Testers
project, supporting the Perl programming language.  See
http://wiki.cpantesters.org/ for more information or email
questions to cpan-testers-discuss@perl.org


--

Dear Graham Knop,

This is a computer-generated error report created automatically by
CPANPLUS, version 0.9908. Testers personal comments may appear
at the end of this report.


Thank you for uploading your work to CPAN.  Congratulations!
All tests were successful.

TEST RESULTS:

Below is the error stack from stage 'make test':

PERL_DL_NONLAZY=1 "/home/cpan/pit/thr/perl-5.30.0/bin/perl" "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness(0, 'blib/lib', 'blib/arch')" t/*.t t/aggregate/*.t
t/01use.t ............................................................. ok
t/abort-chain-1.t ..................................................... ok
t/abort-chain-2.t ..................................................... ok
t/abort-chain-3.t ..................................................... ok
t/accept_context_regression.t ......................................... ok
t/aggregate/c3_appclass_bug.t ......................................... ok
t/aggregate/c3_mro.t .................................................. ok
t/aggregate/caf_backcompat.t .......................................... ok
t/aggregate/catalyst_test_utf8.t ...................................... ok
t/aggregate/custom_live_component_controller_action_auto_doublebug.t .. ok
t/aggregate/custom_live_path_bug.t .................................... ok
t/aggregate/deprecated_test_import.t .................................. ok
t/aggregate/deprecated_test_unimported.t .............................. ok
t/aggregate/error_page_dump.t ......................................... ok
t/aggregate/live_component_controller_action_action.t ................. ok
t/aggregate/live_component_controller_action_auto.t ................... ok
t/aggregate/live_component_controller_action_begin.t .................. ok
t/aggregate/live_component_controller_action_chained.t ................ ok
t/aggregate/live_component_controller_action_chained2.t ............... ok
t/aggregate/live_component_controller_action_default.t ................ ok
t/aggregate/live_component_controller_action_detach.t ................. ok
t/aggregate/live_component_controller_action_die_in_end.t ............. ok
t/aggregate/live_component_controller_action_end.t .................... ok
t/aggregate/live_component_controller_action_forward.t ................ ok
t/aggregate/live_component_controller_action_global.t ................. ok
t/aggregate/live_component_controller_action_go.t ..................... ok
t/aggregate/live_component_controller_action_index.t .................. ok
t/aggregate/live_component_controller_action_index_or_default.t ....... ok
t/aggregate/live_component_controller_action_inheritance.t ............ ok
t/aggregate/live_component_controller_action_local.t .................. ok
t/aggregate/live_component_controller_action_multipath.t .............. ok
t/aggregate/live_component_controller_action_path.t ................... ok
t/aggregate/live_component_controller_action_path_matchsingle.t ....... ok
t/aggregate/live_component_controller_action_private.t ................ ok
t/aggregate/live_component_controller_action_streaming.t .............. ok
t/aggregate/live_component_controller_action_visit.t .................. ok
t/aggregate/live_component_controller_actionroles.t ................... ok
t/aggregate/live_component_controller_anon.t .......................... ok
t/aggregate/live_component_controller_args.t .......................... ok
t/aggregate/live_component_controller_attributes.t .................... ok
t/aggregate/live_component_controller_httpmethods.t ................... ok
t/aggregate/live_component_controller_moose.t ......................... ok
t/aggregate/live_component_view_single.t .............................. ok
t/aggregate/live_engine_request_auth.t ................................ ok
t/aggregate/live_engine_request_body.t ................................ ok
t/aggregate/live_engine_request_body_demand.t ......................... ok
t/aggregate/live_engine_request_cookies.t ............................. ok
t/aggregate/live_engine_request_env.t ................................. ok
t/aggregate/live_engine_request_escaped_path.t ........................ ok
t/aggregate/live_engine_request_headers.t ............................. ok
t/aggregate/live_engine_request_parameters.t .......................... ok
t/aggregate/live_engine_request_prepare_parameters.t .................. ok
t/aggregate/live_engine_request_remote_user.t ......................... ok
t/aggregate/live_engine_request_uploads.t ............................. ok
t/aggregate/live_engine_request_uri.t ................................. ok
t/aggregate/live_engine_response_body.t ............................... ok
t/aggregate/live_engine_response_cookies.t ............................ ok
t/aggregate/live_engine_response_emptybody.t .......................... ok
t/aggregate/live_engine_response_errors.t ............................. ok
t/aggregate/live_engine_response_headers.t ............................ ok
t/aggregate/live_engine_response_large.t .............................. ok
t/aggregate/live_engine_response_print.t .............................. ok
t/aggregate/live_engine_response_redirect.t ........................... ok
t/aggregate/live_engine_response_status.t ............................. ok
t/aggregate/live_engine_setup_basics.t ................................ ok
t/aggregate/live_engine_setup_plugins.t ............................... ok
t/aggregate/live_loop.t ............................................... ok
t/aggregate/live_plugin_loaded.t ...................................... ok
t/aggregate/live_priorities.t ......................................... ok
t/aggregate/live_recursion.t .......................................... ok
t/aggregate/live_view_warnings.t ...................................... ok
t/aggregate/meta_method_unneeded.t .................................... ok
t/aggregate/psgi_file.t ............................................... ok
t/aggregate/to_app.t .................................................. ok
t/aggregate/unit_controller_actions.t ................................. ok
t/aggregate/unit_controller_config.t .................................. ok
t/aggregate/unit_controller_namespace.t ............................... ok
t/aggregate/unit_core_action.t ........................................ ok
t/aggregate/unit_core_action_for.t .................................... ok
t/aggregate/unit_core_appclass_roles_in_plugin_list.t ................. ok
t/aggregate/unit_core_classdata.t ..................................... ok
t/aggregate/unit_core_component.t ..................................... ok
t/aggregate/unit_core_component_generating.t .......................... ok
t/aggregate/unit_core_component_layers.t .............................. ok
t/aggregate/unit_core_component_loading.t ............................. ok
t/aggregate/unit_core_component_mro.t ................................. ok
t/aggregate/unit_core_controller_actions_config.t ..................... ok
t/aggregate/unit_core_ctx_attr.t ...................................... ok
t/aggregate/unit_core_engine-prepare_path.t ........................... ok
t/aggregate/unit_core_engine_fixenv-iis6.t ............................ ok
t/aggregate/unit_core_engine_fixenv-lighttpd.t ........................ ok
t/aggregate/unit_core_log.t ........................................... ok
t/aggregate/unit_core_log_autoflush.t ................................. ok
t/aggregate/unit_core_merge_config_hashes.t ........................... ok
t/aggregate/unit_core_mvc.t ........................................... ok
t/aggregate/unit_core_path_to.t ....................................... ok
t/aggregate/unit_core_plugin.t ........................................ ok
t/aggregate/unit_core_script_cgi.t .................................... ok
t/aggregate/unit_core_script_create.t ................................. ok
t/aggregate/unit_core_script_fastcgi.t ................................ ok
t/aggregate/unit_core_script_help.t ................................... ok
t/aggregate/unit_core_script_run_options.t ............................ ok
t/aggregate/unit_core_script_server-without_modules.t ................. ok
t/aggregate/unit_core_script_server.t ................................. ok
t/aggregate/unit_core_scriptrunner.t .................................. ok
t/aggregate/unit_core_setup.t ......................................... ok
t/aggregate/unit_core_setup_log.t ..................................... ok
t/aggregate/unit_core_setup_stats.t ................................... ok
t/aggregate/unit_core_uri_for.t ....................................... ok
t/aggregate/unit_core_uri_for_action.t ................................ ok
t/aggregate/unit_core_uri_for_multibytechar.t ......................... ok
t/aggregate/unit_core_uri_with.t ...................................... ok
t/aggregate/unit_dispatcher_requestargs_restore.t ..................... ok
t/aggregate/unit_engineloader.t ....................................... ok
t/aggregate/unit_load_catalyst_test.t ................................. ok
t/aggregate/unit_metaclass_compat_extend_non_moose_controller.t ....... ok
t/aggregate/unit_metaclass_compat_non_moose.t ......................... ok
t/aggregate/unit_metaclass_compat_non_moose_controller.t .............. ok
t/aggregate/unit_response.t ........................................... ok
t/aggregate/unit_utils_env_value.t .................................... ok
t/aggregate/unit_utils_home.t ......................................... ok
t/aggregate/unit_utils_prefix.t ....................................... ok
t/aggregate/unit_utils_request.t ...................................... ok
t/aggregate/utf8_content_length.t ..................................... ok
t/arg_constraints.t ................................................... skipped: Trouble loading Type::Tiny and friends => Can't locate Type/Tiny.pm in @INC (you may need to install the Type::Tiny module) (@INC contains: /home/cpan/pit/thr/conf/perl-5.30.0/.cpanplus/5.30.0/build/YgHG5l06lr/Catalyst-Runtime-5.90128/blib/lib /home/cpan/pit/thr/conf/perl-5.30.0/.cpanplus/5.30.0/build/YgHG5l06lr/Catalyst-Runtime-5.90128/blib/arch /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/5.30.0/OpenBSD.amd64-openbsd-thread-multi /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/5.30.0/OpenBSD.amd64-openbsd-thread-multi /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/5.30.0 /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/OpenBSD.amd64-openbsd-thread-multi /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/5.30.0/OpenBSD.amd64-openbsd-thread-multi /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/5.30.0 /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/OpenBSD.amd64-openbsd-thread-multi /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5 /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/5.30.0/OpenBSD.amd64-openbsd-thread-multi /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/5.30.0 /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/OpenBSD.amd64-openbsd-thread-multi /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5 /home/cpan/pit/thr/conf/perl-5.30.0/.cpanplus/5.30.0/build/YgHG5l06lr/Catalyst-Runtime-5.90128/blib/lib /home/cpan/pit/thr/conf/perl-5.30.0/.cpanplus/5.30.0/build/YgHG5l06lr/Catalyst-Runtime-5.90128/blib/arch /home/cpan/pit/thr/perl-5.30.0/lib/site_perl/5.30.0/OpenBSD.amd64-openbsd-thread-multi /home/cpan/pit/thr/perl-5.30.0/lib/site_perl/5.30.0 /home/cpan/pit/thr/perl-5.30.0/lib/5.30.0/OpenBSD.amd64-openbsd-thread-multi /home/cpan/pit/thr/perl-5.30.0/lib/5.30.0 .) at (eval 10) line 1.
t/args-empty-parens-bug.t ............................................. ok
t/args0_bug.t ......................................................... ok
t/bad_middleware_error.t .............................................. ok
t/bad_warnings.t ...................................................... ok
t/body_fh.t ........................................................... ok
t/class_traits.t ...................................................... ok
t/class_traits_CAR_bug.t .............................................. ok
t/configured_comps.t .................................................. ok
t/consumes.t .......................................................... ok
t/content_negotiation.t ............................................... ok
t/custom_exception_class_simple.t ..................................... ok
t/data_handler.t ...................................................... ok
t/dead_load_bad_args.t ................................................ skipped: Removing this test because constraint arg types allow this
t/dead_load_multiple_chained_attributes.t ............................. ok
t/dead_no_unknown_error.t ............................................. ok
t/dead_recursive_chained_attributes.t ................................. ok
t/deprecated.t ........................................................ ok
t/deprecated_appclass_action_warnings.t ............................... ok
t/dispatch_on_scheme.t ................................................ ok
t/encoding_set_in_app.t ............................................... ok
t/encoding_set_in_plugin.t ............................................ ok
t/evil_stash.t ........................................................ ok
t/execute_exception.t ................................................. ok
t/head_middleware.t ................................................... ok
t/http_exceptions.t ................................................... ok
t/http_exceptions_backcompat.t ........................................ ok
t/http_method.t ....................................................... skipped: Test Cases are Sketch for next release
t/inject_component_util.t ............................................. ok
t/live_catalyst_test.t ................................................ ok
t/live_component_controller_context_closure.t ......................... skipped: Devel::Cycle 1.11 required for this test
t/live_fork.t ......................................................... ok
t/live_redirect_body.t ................................................ ok
t/live_show_internal_actions_warnings.t ............................... ok
t/live_stats.t ........................................................ ok
t/middleware-stash.t .................................................. ok
t/more-psgi-compat.t .................................................. ok
t/no_test_stash_bug.t ................................................. ok
t/not_utf8_query_bug.t ................................................ ok
t/optional_http-server-restart.t ...................................... skipped: set TEST_HTTP to enable this test
t/optional_lighttpd-fastcgi-non-root.t ................................ skipped: set TEST_LIGHTTPD to enable this test
t/optional_lighttpd-fastcgi.t ......................................... skipped: set TEST_LIGHTTPD to enable this test
t/optional_memleak.t .................................................. skipped: set TEST_MEMLEAK to enable this test
t/optional_stress.t ................................................... skipped: set TEST_STRESS to enable this test
t/optional_threads.t .................................................. skipped: set TEST_THREADS to enable this test
t/path_action_empty_brackets.t ........................................ ok
t/plack-middleware-plugin.t ........................................... ok
t/plack-middleware.t .................................................. ok
t/plugin_new_method_backcompat.t ...................................... ok
t/psgi-log.t .......................................................... ok
t/psgi_file_testapp.t ................................................. ok
t/psgi_utils.t ........................................................ ok
t/query_constraints.t ................................................. skipped: Trouble loading Type::Tiny and friends => Can't locate Type/Tiny.pm in @INC (you may need to install the Type::Tiny module) (@INC contains: /home/cpan/pit/thr/conf/perl-5.30.0/.cpanplus/5.30.0/build/YgHG5l06lr/Catalyst-Runtime-5.90128/blib/lib /home/cpan/pit/thr/conf/perl-5.30.0/.cpanplus/5.30.0/build/YgHG5l06lr/Catalyst-Runtime-5.90128/blib/arch /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/5.30.0/OpenBSD.amd64-openbsd-thread-multi /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/5.30.0/OpenBSD.amd64-openbsd-thread-multi /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/5.30.0 /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/OpenBSD.amd64-openbsd-thread-multi /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/5.30.0/OpenBSD.amd64-openbsd-thread-multi /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/5.30.0 /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/OpenBSD.amd64-openbsd-thread-multi /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5 /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/5.30.0/OpenBSD.amd64-openbsd-thread-multi /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/5.30.0 /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/OpenBSD.amd64-openbsd-thread-multi /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5 /home/cpan/pit/thr/conf/perl-5.30.0/.cpanplus/5.30.0/build/YgHG5l06lr/Catalyst-Runtime-5.90128/blib/lib /home/cpan/pit/thr/conf/perl-5.30.0/.cpanplus/5.30.0/build/YgHG5l06lr/Catalyst-Runtime-5.90128/blib/arch /home/cpan/pit/thr/perl-5.30.0/lib/site_perl/5.30.0/OpenBSD.amd64-openbsd-thread-multi /home/cpan/pit/thr/perl-5.30.0/lib/site_perl/5.30.0 /home/cpan/pit/thr/perl-5.30.0/lib/5.30.0/OpenBSD.amd64-openbsd-thread-multi /home/cpan/pit/thr/perl-5.30.0/lib/5.30.0 .) at (eval 10) line 1.
t/query_keywords_and_parameters.t ..................................... ok
t/relative_root_action_for_bug.t ...................................... ok
t/remove_redundant_body.t ............................................. ok
t/set_allowed_method.t ................................................ ok
t/state.t ............................................................. ok
t/undef-params.t ...................................................... ok
t/undef_encoding_regression.t ......................................... ok
t/unicode-exception-bug.t ............................................. ok
t/unicode-exception-return-value.t .................................... ok
t/unicode_plugin_charset_utf8.t ....................................... ok
t/unicode_plugin_config.t ............................................. ok
t/unicode_plugin_live.t ............................................... ok
t/unicode_plugin_no_encoding.t ........................................ ok
t/unicode_plugin_request_decode.t ..................................... ok
t/unit_core_methodattributes_method_metaclass_on_subclasses.t ......... ok
t/unit_core_script_test.t ............................................. ok
t/unit_stats.t ........................................................ ok
t/unit_utils_load_class.t ............................................. ok
t/unit_utils_subdir.t ................................................. ok
t/useless_set_headers.t ............................................... ok
t/utf_incoming.t ...................................................... ok
All tests successful.

Test Summary Report
-------------------
t/aggregate/unit_core_uri_for.t                                     (Wstat: 0 Tests: 40 Failed: 0)
  TODO passed:   22
Files=198, Tests=3706, 863 wallclock secs ( 2.72 usr  2.43 sys + 760.09 cusr 81.61 csys = 846.85 CPU)
Result: PASS


PREREQUISITES:

Here is a list of prerequisites you specified and versions we
managed to load:

	  Module Name                        Have     Want
	  CGI::Simple::Cookie                1.25    1.109
	  CGI::Struct                        1.21        0
	  Carp                               1.50     1.25
	  Class::C3::Adopt::NEXT             0.14     0.07
	  Class::Load                        0.25     0.12
	  Data::Dump                         1.23        0
	  Data::OptList                     0.110        0
	  Devel::InnerPackage                 0.4        0
	  Encode                             3.01     2.49
	  HTML::Entities                     3.75        0
	  HTML::HeadParser                   3.75        0
	  HTTP::Body                         1.22     1.22
	  HTTP::Headers                      6.26     1.64
	  HTTP::Request                      6.26    5.814
	  HTTP::Request::Common              6.26        0
	  HTTP::Response                     6.26    5.813
	  HTTP::Status                       6.26        0
	  Hash::MultiValue                   0.16        0
	  JSON::MaybeXS                  1.004002 1.000000
	  LWP                                6.49    5.837
	  List::Util                         1.50     1.45
	  MRO::Compat                        0.13        0
	  Module::Pluggable                   5.2      4.7
	  Moose                            2.2013   2.1400
	  MooseX::Emulate::Class::Accessor::Fast 0.009032  0.00903
	  MooseX::Getopt                     0.74     0.48
	  MooseX::MethodAttributes::Role::AttrContainer::Inheritable     0.32     0.24
	  Path::Class                        0.37     0.09
	  PerlIO::utf8_strict               0.008        0
	  Plack                            1.0047   0.9991
	  Plack::Middleware::Conditional        0        0
	  Plack::Middleware::ContentLength        0        0
	  Plack::Middleware::FixMissingBodyInRedirect     0.12     0.09
	  Plack::Middleware::HTTPExceptions        0        0
	  Plack::Middleware::Head               0        0
	  Plack::Middleware::IIS6ScriptNameFix        0        0
	  Plack::Middleware::IIS7KeepAliveFix        0        0
	  Plack::Middleware::LighttpdScriptNameFix        0        0
	  Plack::Middleware::MethodOverride     0.20     0.12
	  Plack::Middleware::RemoveRedundantBody     0.09     0.03
	  Plack::Middleware::ReverseProxy     0.16     0.04
	  Plack::Request::Upload                0        0
	  Plack::Test::ExternalServer        0.02        0
	  Safe::Isa                      1.000010        0
	  Scalar::Util                       1.50        0
	  Socket                            2.027     1.96
	  Stream::Buffered                   0.03        0
	  String::RewritePrefix             0.008    0.004
	  Sub::Exporter                     0.987        0
	  Task::Weaken                       1.06        0
	  Test::Fatal                       0.016        0
	  Test::More                     1.302181     0.88
	  Text::Balanced                     2.03        0
	  Text::SimpleTable                  2.07     0.03
	  Time::HiRes                      1.9760        0
	  Tree::Simple                       1.33     1.15
	  Tree::Simple::Visitor::FindByUID     0.15        0
	  Try::Tiny                          0.30     0.17
	  URI                                5.05     1.65
	  URI::ws                            0.03     0.03
	  namespace::clean                   0.27     0.23

Perl module toolchain versions installed:
	Module Name                        Have
	CPANPLUS                         0.9908
	CPANPLUS::Dist::Build              0.90
	Cwd                                3.78
	ExtUtils::CBuilder             0.280234
	ExtUtils::Command                  7.48
	ExtUtils::Install                  2.18
	ExtUtils::MakeMaker                7.48
	ExtUtils::Manifest                 1.72
	ExtUtils::ParseXS                  3.40
	File::Spec                         3.78
	Module::Build                    0.4231
	Pod::Parser                        1.63
	Pod::Simple                        3.35
	Test2                          1.302181
	Test::Harness                      3.42
	Test::More                     1.302181
	version                          0.9928

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
    PATH = /home/cpan/pit/thr/conf/perl-5.30.0/.cpanplus/5.30.0/build/YgHG5l06lr/Catalyst-Runtime-5.90128/blib/script:/home/cpan/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/X11R6/bin:/usr/local/bin:/usr/local/sbin:/usr/games
    PERL5LIB = /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5:/home/cpan/pit/thr/conf/perl-5.30.0/.cpanplus/5.30.0/build/YgHG5l06lr/Catalyst-Runtime-5.90128/blib/lib:/home/cpan/pit/thr/conf/perl-5.30.0/.cpanplus/5.30.0/build/YgHG5l06lr/Catalyst-Runtime-5.90128/blib/arch
    PERL5_CPANPLUS_IS_RUNNING = 59856
    PERL5_CPANPLUS_IS_VERSION = 0.9908
    PERL5_MINISMOKEBOX = 0.68
    PERL5_YACSMOKE_BASE = /home/cpan/pit/thr/conf/perl-5.30.0
    PERL_EXTUTILS_AUTOINSTALL = --defaultdeps
    PERL_LOCAL_LIB_ROOT = /home/cpan/pit/jail/_A7rwLQ0Kr
    PERL_MB_OPT = --install_base "/home/cpan/pit/jail/_A7rwLQ0Kr"
    PERL_MM_OPT = INSTALL_BASE=/home/cpan/pit/jail/_A7rwLQ0Kr
    PERL_MM_USE_DEFAULT = 1
    PERL_USE_UNSAFE_INC = 1
    SHELL = /usr/local/bin/bash
    TERM = screen

Perl special variables (and OS-specific diagnostics, for MSWin32):

    Perl: $^X = /home/cpan/pit/thr/perl-5.30.0/bin/perl
    UID:  $<  = 1001
    EUID: $>  = 1001
    GID:  $(  = 1001 1001
    EGID: $)  = 1001 1001


-------------------------------


--

Summary of my perl5 (revision 5 version 30 subversion 0) configuration:
   
  Platform:
    osname=openbsd
    osvers=6.6
    archname=OpenBSD.amd64-openbsd-thread-multi
    uname='openbsd outrage.bingosnet.co.uk 6.6 generic#4 amd64 '
    config_args='-des -Dprefix=/home/cpan/pit/thr/perl-5.30.0 -Dusethreads'
    hint=recommended
    useposix=true
    d_sigaction=define
    useithreads=define
    usemultiplicity=define
    use64bitint=define
    use64bitall=define
    uselongdouble=undef
    usemymalloc=n
    default_inc_excludes_dot=define
    bincompat5005=undef
  Compiler:
    cc='cc'
    ccflags ='-pthread -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/local/include -D_FORTIFY_SOURCE=2'
    optimize='-O2'
    cppflags='-pthread -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/local/include'
    ccversion=''
    gccversion='4.2.1 Compatible OpenBSD Clang 8.0.1 (tags/RELEASE_801/final)'
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
    ldflags ='-pthread -Wl,-E  -fstack-protector-strong -L/usr/local/lib'
    libpth=/usr/lib /usr/local/lib
    libs=-lpthread -lgdbm -lm -lutil -lc
    perllibs=-lpthread -lm -lutil -lc
    libc=/usr/lib/libc.so.95.1
    so=so
    useshrplib=false
    libperl=libperl.a
    gnulibc_version=''
  Dynamic Linking:
    dlsrc=dl_dlopen.xs
    dlext=so
    d_dlsymun=undef
    ccdlflags=' '
    cccdlflags='-DPIC -fPIC '
    lddlflags='-shared -fPIC  -L/usr/local/lib -fstack-protector-strong'


Characteristics of this binary (from libperl): 
  Compile-time options:
    HAS_TIMES
    MULTIPLICITY
    PERLIO_LAYERS
    PERL_COPY_ON_WRITE
    PERL_DONT_CREATE_GVSV
    PERL_IMPLICIT_CONTEXT
    PERL_MALLOC_WRAP
    PERL_OP_PARENT
    PERL_PRESERVE_IVUV
    USE_64_BIT_ALL
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
    USE_REENTRANT_API
  Locally applied patches:
    Devel::PatchPerl 1.80
  Built under openbsd
  Compiled at Jan 24 2020 14:17:27
  %ENV:
    PERL5LIB="/home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5:/home/cpan/pit/thr/conf/perl-5.30.0/.cpanplus/5.30.0/build/YgHG5l06lr/Catalyst-Runtime-5.90128/blib/lib:/home/cpan/pit/thr/conf/perl-5.30.0/.cpanplus/5.30.0/build/YgHG5l06lr/Catalyst-Runtime-5.90128/blib/arch"
    PERL5_CPANPLUS_IS_RUNNING="59856"
    PERL5_CPANPLUS_IS_VERSION="0.9908"
    PERL5_MINISMOKEBOX="0.68"
    PERL5_YACSMOKE_BASE="/home/cpan/pit/thr/conf/perl-5.30.0"
    PERL_EXTUTILS_AUTOINSTALL="--defaultdeps"
    PERL_LOCAL_LIB_ROOT="/home/cpan/pit/jail/_A7rwLQ0Kr"
    PERL_MB_OPT="--install_base "/home/cpan/pit/jail/_A7rwLQ0Kr""
    PERL_MM_OPT="INSTALL_BASE=/home/cpan/pit/jail/_A7rwLQ0Kr"
    PERL_MM_USE_DEFAULT="1"
    PERL_USE_UNSAFE_INC="1"
  @INC:
    /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/5.30.0/OpenBSD.amd64-openbsd-thread-multi
    /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/5.30.0
    /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5/OpenBSD.amd64-openbsd-thread-multi
    /home/cpan/pit/jail/_A7rwLQ0Kr/lib/perl5
    /home/cpan/pit/thr/conf/perl-5.30.0/.cpanplus/5.30.0/build/YgHG5l06lr/Catalyst-Runtime-5.90128/blib/lib
    /home/cpan/pit/thr/conf/perl-5.30.0/.cpanplus/5.30.0/build/YgHG5l06lr/Catalyst-Runtime-5.90128/blib/arch
    /home/cpan/pit/thr/perl-5.30.0/lib/site_perl/5.30.0/OpenBSD.amd64-openbsd-thread-multi
    /home/cpan/pit/thr/perl-5.30.0/lib/site_perl/5.30.0
    /home/cpan/pit/thr/perl-5.30.0/lib/5.30.0/OpenBSD.amd64-openbsd-thread-multi
    /home/cpan/pit/thr/perl-5.30.0/lib/5.30.0
    .

@@ report-cpanplus-0.9113.txt

This distribution has been tested as part of the CPAN Testers
project, supporting the Perl programming language.  See
http://wiki.cpantesters.org/ for more information or email
questions to cpan-testers-discuss@perl.org


--

Dear XAICRON,

This is a computer-generated error report created automatically by
CPANPLUS, version 0.9113. Testers personal comments may appear
at the end of this report.

MAKE TEST passed: PERL_DL_NONLAZY=1 /home/cpan/pit/rel/perl-5.12.1/bin/perl "-MExtUtils::Command::MM" "-e" "test_harness(0, 'inc', 'blib/lib', 'blib/arch')" t/*.t t/*/*.t t/*/*/*.t
t/00_compile.t ....... ok
t/01_new.t ........... ok
t/02_authenticate.t .. ok
All tests successful.
Files=3, Tests=56,  3 wallclock secs ( 0.06 usr  0.11 sys +  0.48 cusr  1.57 csys =  2.22 CPU)
Result: PASS

[MSG] [Sat Jan 14 11:43:37 2012] Sending test report for 'WWW-Google-ClientLogin-0.02'

PREREQUISITES:

Here is a list of prerequisites you specified and versions we
managed to load:

	  Module Name                        Have     Want
	  Carp                               1.16        0
	  ExtUtils::MakeMaker                6.62     6.62
	  HTTP::Request::Common              6.00        0
	  LWP::Protocol::https               6.02        0
	  LWP::UserAgent                     6.03        0
	  Test::Fake::HTTPD                  0.03     0.03
	  Test::Flatten                      0.07     0.06
	  Test::More                         0.98     0.98
	  Test::SharedFork                   0.19     0.18
	  URI::Escape                        3.31        0

Perl module toolchain versions installed:
	Module Name                        Have
	CPANPLUS                         0.9113
	CPANPLUS::Dist::Build              0.60
	Cwd                                3.33
	ExtUtils::CBuilder             0.280202
	ExtUtils::Command                  1.16
	ExtUtils::Install                  1.55
	ExtUtils::MakeMaker                6.62
	ExtUtils::Manifest                 1.60
	ExtUtils::ParseXS                  3.07
	File::Spec                         3.33
	Module::Build                    0.3800
	Test::Harness                      3.23
	Test::More                         0.98
	version                            0.95

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


This report was machine-generated by CPANPLUS::Dist::YACSmoke 0.66.
Powered by minismokebox version 0.54

------------------------------
ENVIRONMENT AND OTHER CONTEXT
------------------------------

Environment variables:

    AUTOMATED_TESTING = 1
    PATH = /home/cpan/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/X11R6/bin:/usr/local/bin:/usr/local/sbin:/usr/games:.
    PERL5LIB = :/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Encode-Locale-1.02/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Encode-Locale-1.02/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTML-Tagset-3.20/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTML-Tagset-3.20/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTML-Parser-3.69/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTML-Parser-3.69/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Date-6.00/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Date-6.00/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/LWP-MediaTypes-6.01/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/LWP-MediaTypes-6.01/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/URI-1.59/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/URI-1.59/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Message-6.02/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Message-6.02/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Net-SSLeay-1.42/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Net-SSLeay-1.42/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/IO-Socket-SSL-1.54/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/IO-Socket-SSL-1.54/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/File-Listing-6.03/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/File-Listing-6.03/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Cookies-6.00/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Cookies-6.00/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Daemon-6.00/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Daemon-6.00/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Negotiate-6.00/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Negotiate-6.00/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Net-HTTP-6.02/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Net-HTTP-6.02/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/WWW-RobotRules-6.01/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/WWW-RobotRules-6.01/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/libwww-perl-6.03/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/libwww-perl-6.03/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Mozilla-CA-20111025/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Mozilla-CA-20111025/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/LWP-Protocol-https-6.02/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/LWP-Protocol-https-6.02/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Devel-StackTrace-1.27/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Devel-StackTrace-1.27/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Devel-StackTrace-AsHTML-0.11/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Devel-StackTrace-AsHTML-0.11/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Class-Inspector-1.25/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Class-Inspector-1.25/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/File-ShareDir-1.03/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/File-ShareDir-1.03/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Requires-0.06/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Requires-0.06/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-SharedFork-0.19/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-SharedFork-0.19/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Filesys-Notify-Simple-0.08/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Filesys-Notify-Simple-0.08/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Tester-0.108/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Tester-0.108/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-NoWarnings-1.04/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-NoWarnings-1.04/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Deep-0.108/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Deep-0.108/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Body-1.15/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Body-1.15/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Hash-MultiValue-0.10/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Hash-MultiValue-0.10/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-TCP-1.14/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-TCP-1.14/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Try-Tiny-0.11/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Try-Tiny-0.11/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Plack-0.9985/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Plack-0.9985/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Sub-Uplevel-0.22/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Sub-Uplevel-0.22/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Exception-0.31/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Exception-0.31/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Flatten-0.07/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Flatten-0.07/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-UseAllModules-0.13/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-UseAllModules-0.13/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Fake-HTTPD-0.03/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Fake-HTTPD-0.03/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/WWW-Google-ClientLogin-0.02/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/WWW-Google-ClientLogin-0.02/blib/arch
    PERL5_CPANPLUS_IS_RUNNING = 13871
    PERL5_CPANPLUS_IS_VERSION = 0.9113
    PERL5_MINISMOKEBOX = 0.54
    PERL5_YACSMOKE_BASE = /home/cpan/pit/rel/conf/perl-5.12.1
    PERL_EXTUTILS_AUTOINSTALL = --defaultdeps
    PERL_MM_USE_DEFAULT = 1
    SHELL = /usr/local/bin/bash
    TERM = screen

Perl special variables (and OS-specific diagnostics, for MSWin32):

    Perl: $^X = /home/cpan/pit/rel/perl-5.12.1/bin/perl
    UID:  $<  = 1001
    EUID: $>  = 1001
    GID:  $(  = 1001 1001
    EGID: $)  = 1001 1001


-------------------------------


--

Summary of my perl5 (revision 5 version 12 subversion 1) configuration:
   
  Platform:
    osname=openbsd, osvers=5.0, archname=OpenBSD.i386-openbsd-thread-multi-64int
    uname='openbsd oatcake.bingosnet.co.uk 5.0 generic#43 i386 '
    config_args='-des -Dprefix=/home/cpan/pit/rel/perl-5.12.1 -Dusethreads -Duse64bitint'
    hint=recommended, useposix=true, d_sigaction=define
    useithreads=define, usemultiplicity=define
    useperlio=define, d_sfio=undef, uselargefiles=define, usesocks=undef
    use64bitint=define, use64bitall=undef, uselongdouble=undef
    usemymalloc=y, bincompat5005=undef
  Compiler:
    cc='cc', ccflags ='-pthread -fno-strict-aliasing -pipe -fstack-protector -I/usr/local/include',
    optimize='-O2',
    cppflags='-pthread -fno-strict-aliasing -pipe -fstack-protector -I/usr/local/include'
    ccversion='', gccversion='4.2.1 20070719 ', gccosandvers='openbsd5.0'
    intsize=4, longsize=4, ptrsize=4, doublesize=8, byteorder=12345678
    d_longlong=define, longlongsize=8, d_longdbl=define, longdblsize=12
    ivtype='long long', ivsize=8, nvtype='double', nvsize=8, Off_t='off_t', lseeksize=8
    alignbytes=4, prototype=define
  Linker and Libraries:
    ld='cc', ldflags ='-pthread -Wl,-E  -fstack-protector -L/usr/local/lib'
    libpth=/usr/local/lib /usr/lib
    libs=-lgdbm -lm -lutil -lc
    perllibs=-lm -lutil -lc
    libc=/usr/lib/libc.so.60.1, so=so, useshrplib=false, libperl=libperl.a
    gnulibc_version=''
  Dynamic Linking:
    dlsrc=dl_dlopen.xs, dlext=so, d_dlsymun=undef, ccdlflags=' '
    cccdlflags='-DPIC -fPIC ', lddlflags='-shared -fPIC  -L/usr/local/lib -fstack-protector'


Characteristics of this binary (from libperl): 
  Compile-time options: MULTIPLICITY MYMALLOC PERL_DONT_CREATE_GVSV
                        PERL_IMPLICIT_CONTEXT PERL_MALLOC_WRAP USE_64_BIT_INT
                        USE_ITHREADS USE_LARGE_FILES USE_PERLIO USE_PERL_ATOF
                        USE_REENTRANT_API
  Built under openbsd
  Compiled at Dec  2 2011 06:15:39
  %ENV:
    PERL5LIB=":/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Encode-Locale-1.02/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Encode-Locale-1.02/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTML-Tagset-3.20/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTML-Tagset-3.20/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTML-Parser-3.69/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTML-Parser-3.69/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Date-6.00/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Date-6.00/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/LWP-MediaTypes-6.01/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/LWP-MediaTypes-6.01/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/URI-1.59/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/URI-1.59/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Message-6.02/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Message-6.02/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Net-SSLeay-1.42/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Net-SSLeay-1.42/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/IO-Socket-SSL-1.54/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/IO-Socket-SSL-1.54/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/File-Listing-6.03/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/File-Listing-6.03/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Cookies-6.00/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Cookies-6.00/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Daemon-6.00/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Daemon-6.00/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Negotiate-6.00/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Negotiate-6.00/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Net-HTTP-6.02/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Net-HTTP-6.02/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/WWW-RobotRules-6.01/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/WWW-RobotRules-6.01/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/libwww-perl-6.03/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/libwww-perl-6.03/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Mozilla-CA-20111025/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Mozilla-CA-20111025/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/LWP-Protocol-https-6.02/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/LWP-Protocol-https-6.02/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Devel-StackTrace-1.27/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Devel-StackTrace-1.27/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Devel-StackTrace-AsHTML-0.11/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Devel-StackTrace-AsHTML-0.11/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Class-Inspector-1.25/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Class-Inspector-1.25/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/File-ShareDir-1.03/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/File-ShareDir-1.03/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Requires-0.06/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Requires-0.06/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-SharedFork-0.19/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-SharedFork-0.19/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Filesys-Notify-Simple-0.08/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Filesys-Notify-Simple-0.08/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Tester-0.108/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Tester-0.108/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-NoWarnings-1.04/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-NoWarnings-1.04/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Deep-0.108/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Deep-0.108/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Body-1.15/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Body-1.15/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Hash-MultiValue-0.10/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Hash-MultiValue-0.10/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-TCP-1.14/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-TCP-1.14/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Try-Tiny-0.11/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Try-Tiny-0.11/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Plack-0.9985/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Plack-0.9985/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Sub-Uplevel-0.22/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Sub-Uplevel-0.22/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Exception-0.31/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Exception-0.31/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Flatten-0.07/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Flatten-0.07/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-UseAllModules-0.13/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-UseAllModules-0.13/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Fake-HTTPD-0.03/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Fake-HTTPD-0.03/blib/arch:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/WWW-Google-ClientLogin-0.02/blib/lib:/home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/WWW-Google-ClientLogin-0.02/blib/arch"
    PERL5_CPANPLUS_IS_RUNNING="13871"
    PERL5_CPANPLUS_IS_VERSION="0.9113"
    PERL5_MINISMOKEBOX="0.54"
    PERL5_YACSMOKE_BASE="/home/cpan/pit/rel/conf/perl-5.12.1"
    PERL_EXTUTILS_AUTOINSTALL="--defaultdeps"
    PERL_MM_USE_DEFAULT="1"
  @INC:
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Encode-Locale-1.02/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Encode-Locale-1.02/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTML-Tagset-3.20/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTML-Tagset-3.20/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTML-Parser-3.69/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTML-Parser-3.69/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Date-6.00/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Date-6.00/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/LWP-MediaTypes-6.01/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/LWP-MediaTypes-6.01/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/URI-1.59/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/URI-1.59/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Message-6.02/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Message-6.02/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Net-SSLeay-1.42/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Net-SSLeay-1.42/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/IO-Socket-SSL-1.54/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/IO-Socket-SSL-1.54/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/File-Listing-6.03/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/File-Listing-6.03/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Cookies-6.00/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Cookies-6.00/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Daemon-6.00/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Daemon-6.00/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Negotiate-6.00/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Negotiate-6.00/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Net-HTTP-6.02/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Net-HTTP-6.02/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/WWW-RobotRules-6.01/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/WWW-RobotRules-6.01/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/libwww-perl-6.03/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/libwww-perl-6.03/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Mozilla-CA-20111025/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Mozilla-CA-20111025/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/LWP-Protocol-https-6.02/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/LWP-Protocol-https-6.02/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Devel-StackTrace-1.27/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Devel-StackTrace-1.27/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Devel-StackTrace-AsHTML-0.11/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Devel-StackTrace-AsHTML-0.11/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Class-Inspector-1.25/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Class-Inspector-1.25/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/File-ShareDir-1.03/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/File-ShareDir-1.03/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Requires-0.06/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Requires-0.06/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-SharedFork-0.19/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-SharedFork-0.19/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Filesys-Notify-Simple-0.08/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Filesys-Notify-Simple-0.08/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Tester-0.108/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Tester-0.108/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-NoWarnings-1.04/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-NoWarnings-1.04/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Deep-0.108/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Deep-0.108/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Body-1.15/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/HTTP-Body-1.15/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Hash-MultiValue-0.10/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Hash-MultiValue-0.10/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-TCP-1.14/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-TCP-1.14/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Try-Tiny-0.11/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Try-Tiny-0.11/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Plack-0.9985/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Plack-0.9985/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Sub-Uplevel-0.22/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Sub-Uplevel-0.22/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Exception-0.31/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Exception-0.31/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Flatten-0.07/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Flatten-0.07/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-UseAllModules-0.13/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-UseAllModules-0.13/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Fake-HTTPD-0.03/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/Test-Fake-HTTPD-0.03/blib/arch
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/WWW-Google-ClientLogin-0.02/blib/lib
    /home/cpan/pit/rel/conf/perl-5.12.1/.cpanplus/5.12.1/build/WWW-Google-ClientLogin-0.02/blib/arch
    /home/cpan/pit/rel/perl-5.12.1/lib/site_perl/5.12.1/OpenBSD.i386-openbsd-thread-multi-64int
    /home/cpan/pit/rel/perl-5.12.1/lib/site_perl/5.12.1
    /home/cpan/pit/rel/perl-5.12.1/lib/5.12.1/OpenBSD.i386-openbsd-thread-multi-64int
    /home/cpan/pit/rel/perl-5.12.1/lib/5.12.1
    .

@@ report-cpanplus-0.9908-with-yath.txt

This distribution has been tested as part of the CPAN Testers
project, supporting the Perl programming language.  See
http://wiki.cpantesters.org/ for more information or email
questions to cpan-testers-discuss@perl.org


--

Dear EXODIST,

This is a computer-generated error report created automatically by
CPANPLUS, version 0.9908. Testers personal comments may appear
at the end of this report.


Thank you for uploading your work to CPAN.  Congratulations!
All tests were successful.

TEST RESULTS:

Below is the error stack from stage 'make test':

PERL_DL_NONLAZY=1 "/home/cpan/pit/thr/perl-5.32.0/bin/perl" "-Iblib/lib" "-Iblib/arch" test.pl
1..2
( PASSED )  job  1    t/integration/failure_cases.t
( PASSED )  job  2    t/integration/retry.t
( PASSED )  job  3    t/0-load_all.t
( PASSED )  job  4    t/1-pod_name.t
( PASSED )  job  5    t/HashBase.t
( PASSED )  job  6    t/integration/concurrency.t
( PASSED )  job  7    t/integration/encoding.t
( PASSED )  job  8    t/integration/failed.t
( PASSED )  job  9    t/integration/help.t
( PASSED )  job 10    t/integration/includes.t
( PASSED )  job 11    t/integration/init.t
( PASSED )  job 12    t/integration/log_dir.t
( SKIPPED)  job 13    t/integration/persist.t  -  This test is not run under automated testing
( PASSED )  job 14    t/integration/plugin.t
( PASSED )  job 15    t/integration/preload.t
( PASSED )  job 16    t/integration/projects.t
( PASSED )  job 17    t/integration/replay.t
( PASSED )  job 18    t/integration/resource.t
( SKIPPED)  job 19    t/integration/signals.t  -  Author test, set the $AUTHOR_TESTING environment variable to run it
( PASSED )  job 20    t/integration/signals/abrt_or_iot.t
( PASSED )  job 21    t/integration/smoke.t
( PASSED )  job 22    t/integration/speedtag.t
( PASSED )  job 23    t/integration/stamps.t
( PASSED )  job 24    t/integration/test.t
( PASSED )  job 25    t/integration/times.t
( PASSED )  job 26    t/integration/verbose_env.t
( PASSED )  job 27    t/unit/App/Yath.t
( PASSED )  job 28    t/unit/App/Yath/Option.t
( PASSED )  job 29    t/unit/App/Yath/Options.t
( PASSED )  job 30    t/unit/App/Yath/Plugin.t
( PASSED )  job 31    t/unit/App/Yath/Util.t
( SKIPPED)  job 32    t/unit/Test2/Harness/Runner/DepTracer.t  -  TODO
( PASSED )  job 33    t/unit/Test2/Harness/Settings.t
( PASSED )  job 34    t/unit/Test2/Harness/Settings/Prefix.t
( SKIPPED)  job 35    t/unit/Test2/Harness/Util.t  -  TODO
( PASSED )  job 36    t/unit/Test2/Tools/HarnessTester.t
( PASSED )  job 37    t/yath_script.t
( PASSED )  job 38    t2/subtests.t
( PASSED )  job 39    t2/tmp_perms.t
( PASSED )  job 40    t2/vars.t
( PASSED )  job 41    t/unit/App/Yath/Command/init.t
( PASSED )  job 42    t/unit/App/Yath/Plugin/Git.t
( PASSED )  job 43    t/unit/App/Yath/Plugin/SysInfo.t
( PASSED )  job 44    t/unit/Test2/Harness/TestFile.t
( PASSED )  job 45    t/unit/Test2/Harness/Util/File.t
( PASSED )  job 46    t/unit/Test2/Harness/Util/File/JSON.t
( PASSED )  job 47    t/unit/Test2/Harness/Util/File/JSONL.t
( PASSED )  job 48    t/unit/Test2/Harness/Util/File/Stream.t
( PASSED )  job 49    t/unit/Test2/Harness/Util/File/Value.t
( PASSED )  job 50    t/unit/Test2/Harness/Util/JSON.t
( PASSED )  job 51    t/unit/Test2/Harness/Util/Term.t
( PASSED )  job 52    t2/builder.t
( PASSED )  job 53    t2/caller.t
( PASSED )  job 54    t2/data.t
( PASSED )  job 55    t2/ending.t
( PASSED )  job 56    t2/exception.t
( PASSED )  job 57    t2/findbin.t
( PASSED )  job 58    t2/ipc_reexec.t
( PASSED )  job 59    t2/magic_vars.t
( PASSED )  job 60    t2/no_stdout_eol.t
( SKIPPED)  job 61    t2/output.t  -  Author test, set the $AUTHOR_TESTING environment variable to run it
( PASSED )  job 62    t2/relative_paths.t
( PASSED )  job 63    t2/relative_paths_no_fork.t
( PASSED )  job 64    t2/require_file.t
( PASSED )  job 65    t2/simple.t
( PASSED )  job 66    t2/subtests_buffered.t
( PASSED )  job 67    t2/subtests_streamed.t
( PASSED )  job 68    t2/utf8-2.t
( PASSED )  job 69    t2/utf8.t

                                  Yath Result Summary
----------------------------------------------------------------------------------------
     File Count: 69
Assertion Count: 1574
      Wall Time: 137.68 seconds
       CPU Time: 135.81 seconds (usr: 3.26s | sys: 0.08s | cusr: 105.55s | csys: 26.92s)
      CPU Usage: 98%
    -->  Result: PASSED  <--
[0m
( PASSED )  job  1    t/integration/failure_cases.t
( PASSED )  job  2    t/integration/retry.t
( PASSED )  job  3    t/0-load_all.t
( PASSED )  job  4    t/1-pod_name.t
( PASSED )  job  5    t/HashBase.t
( PASSED )  job  6    t/integration/concurrency.t
( PASSED )  job  7    t/integration/encoding.t
( PASSED )  job  8    t/integration/failed.t
( PASSED )  job  9    t/integration/help.t
( PASSED )  job 10    t/integration/includes.t
( PASSED )  job 11    t/integration/init.t
( PASSED )  job 12    t/integration/log_dir.t
( SKIPPED)  job 13    t/integration/persist.t  -  This test is not run under automated testing
( PASSED )  job 14    t/integration/plugin.t
( SKIPPED)  job 15    t/integration/preload.t  -  This test requires forking
( PASSED )  job 16    t/integration/projects.t
( PASSED )  job 17    t/integration/replay.t
( PASSED )  job 18    t/integration/resource.t
( SKIPPED)  job 19    t/integration/signals.t  -  Author test, set the $AUTHOR_TESTING environment variable to run it
( PASSED )  job 20    t/integration/signals/abrt_or_iot.t
( PASSED )  job 21    t/integration/smoke.t
( PASSED )  job 22    t/integration/speedtag.t
( PASSED )  job 23    t/integration/stamps.t
( PASSED )  job 24    t/integration/test.t
( PASSED )  job 25    t/integration/times.t
( PASSED )  job 26    t/integration/verbose_env.t
( PASSED )  job 27    t/unit/App/Yath.t
( PASSED )  job 28    t/unit/App/Yath/Option.t
( PASSED )  job 29    t/unit/App/Yath/Options.t
( PASSED )  job 30    t/unit/App/Yath/Plugin.t
( PASSED )  job 31    t/unit/App/Yath/Util.t
( SKIPPED)  job 32    t/unit/Test2/Harness/Runner/DepTracer.t  -  TODO
( PASSED )  job 33    t/unit/Test2/Harness/Settings.t
( PASSED )  job 34    t/unit/Test2/Harness/Settings/Prefix.t
( SKIPPED)  job 35    t/unit/Test2/Harness/Util.t  -  TODO
( PASSED )  job 36    t/unit/Test2/Tools/HarnessTester.t
( PASSED )  job 37    t/yath_script.t
( PASSED )  job 38    t2/subtests.t
( PASSED )  job 39    t2/tmp_perms.t
( PASSED )  job 40    t2/vars.t
( PASSED )  job 41    t/unit/App/Yath/Command/init.t
( PASSED )  job 42    t/unit/App/Yath/Plugin/Git.t
( PASSED )  job 43    t/unit/App/Yath/Plugin/SysInfo.t
( PASSED )  job 44    t/unit/Test2/Harness/TestFile.t
( PASSED )  job 45    t/unit/Test2/Harness/Util/File.t
( PASSED )  job 46    t/unit/Test2/Harness/Util/File/JSON.t
( PASSED )  job 47    t/unit/Test2/Harness/Util/File/JSONL.t
( PASSED )  job 48    t/unit/Test2/Harness/Util/File/Stream.t
( PASSED )  job 49    t/unit/Test2/Harness/Util/File/Value.t
( PASSED )  job 50    t/unit/Test2/Harness/Util/JSON.t
( PASSED )  job 51    t/unit/Test2/Harness/Util/Term.t
( PASSED )  job 52    t2/builder.t
( PASSED )  job 53    t2/caller.t
( PASSED )  job 54    t2/data.t
( PASSED )  job 55    t2/ending.t
( PASSED )  job 56    t2/exception.t
( PASSED )  job 57    t2/findbin.t
( PASSED )  job 58    t2/ipc_reexec.t
( PASSED )  job 59    t2/magic_vars.t
( PASSED )  job 60    t2/no_stdout_eol.t
( SKIPPED)  job 61    t2/output.t  -  Author test, set the $AUTHOR_TESTING environment variable to run it
( PASSED )  job 62    t2/relative_paths.t
( PASSED )  job 63    t2/relative_paths_no_fork.t
( PASSED )  job 64    t2/require_file.t
( PASSED )  job 65    t2/simple.t
( PASSED )  job 66    t2/subtests_buffered.t
( PASSED )  job 67    t2/subtests_streamed.t
( PASSED )  job 68    t2/utf8-2.t
( PASSED )  job 69    t2/utf8.t

                                  Yath Result Summary
----------------------------------------------------------------------------------------
     File Count: 69
Assertion Count: 1553
      Wall Time: 145.22 seconds
       CPU Time: 143.50 seconds (usr: 3.18s | sys: 0.08s | cusr: 112.77s | csys: 27.47s)
      CPU Usage: 98%
    -->  Result: PASSED  <--
[0m
ok 1 - Passed tests when run by yath (allow fork)
ok 2 - Passed tests when run by yath (no fork)
PERL_DL_NONLAZY=1 "/home/cpan/pit/thr/perl-5.32.0/bin/perl" "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness(0, 'blib/lib', 'blib/arch')" t/*.t t/integration/*.t t/integration/signals/*.t t/unit/App/*.t t/unit/App/Yath/*.t t/unit/App/Yath/Command/*.t t/unit/App/Yath/Plugin/*.t t/unit/Test2/Harness/*.t t/unit/Test2/Harness/Runner/*.t t/unit/Test2/Harness/Settings/*.t t/unit/Test2/Harness/Util/*.t t/unit/Test2/Harness/Util/File/*.t t/unit/Test2/Tools/*.t
t/0-load_all.t ........................... ok
t/1-pod_name.t ........................... ok
t/HashBase.t ............................. ok
t/integration/concurrency.t .............. ok
t/integration/encoding.t ................. ok
t/integration/failed.t ................... ok
t/integration/failure_cases.t ............ ok
t/integration/help.t ..................... ok
t/integration/includes.t ................. ok
t/integration/init.t ..................... ok
t/integration/log_dir.t .................. ok
t/integration/persist.t .................. skipped: This test is not run under automated testing
t/integration/plugin.t ................... ok
t/integration/preload.t .................. ok
t/integration/projects.t ................. ok
t/integration/replay.t ................... ok
t/integration/resource.t ................. ok
t/integration/retry.t .................... ok
t/integration/signals.t .................. skipped: Author test, set the $AUTHOR_TESTING environment variable to run it
t/integration/signals/abrt_or_iot.t ...... ok
t/integration/smoke.t .................... ok
t/integration/speedtag.t ................. ok
t/integration/stamps.t ................... ok
t/integration/test.t ..................... ok
t/integration/times.t .................... ok
t/integration/verbose_env.t .............. ok
t/unit/App/Yath.t ........................ ok
t/unit/App/Yath/Command/init.t ........... ok
t/unit/App/Yath/Option.t ................. ok
t/unit/App/Yath/Options.t ................ ok
t/unit/App/Yath/Plugin.t ................. ok
t/unit/App/Yath/Plugin/Git.t ............. ok
t/unit/App/Yath/Plugin/SysInfo.t ......... ok
t/unit/App/Yath/Util.t ................... ok
t/unit/Test2/Harness/Runner/DepTracer.t .. skipped: TODO
t/unit/Test2/Harness/Settings.t .......... ok
t/unit/Test2/Harness/Settings/Prefix.t ... ok
t/unit/Test2/Harness/TestFile.t .......... ok
t/unit/Test2/Harness/Util.t .............. skipped: TODO
t/unit/Test2/Harness/Util/File.t ......... ok
t/unit/Test2/Harness/Util/File/JSON.t .... ok
t/unit/Test2/Harness/Util/File/JSONL.t ... ok
t/unit/Test2/Harness/Util/File/Stream.t .. ok
t/unit/Test2/Harness/Util/File/Value.t ... ok
t/unit/Test2/Harness/Util/JSON.t ......... ok
t/unit/Test2/Harness/Util/Term.t ......... ok
t/unit/Test2/Tools/HarnessTester.t ....... ok
t/yath_script.t .......................... ok
All tests successful.
Files=48, Tests=798, 124 wallclock secs ( 0.19 usr  0.05 sys + 96.63 cusr 26.00 csys = 122.87 CPU)
Result: PASS


PREREQUISITES:

Here is a list of prerequisites you specified and versions we
managed to load:

	  Module Name                        Have     Want
	  Carp                               1.50        0
	  Cwd                                3.78        0
	  Data::Dumper                      2.174        0
	  Data::UUID                        1.226        0
	  Exporter                           5.74        0
	  ExtUtils::MakeMaker                7.48        0
	  Fcntl                              1.13        0
	  File::Copy                         2.34        0
	  File::Find                         1.37        0
	  File::Path                         2.17     2.11
	  File::Spec                         3.78        0
	  File::Temp                       0.2311        0
	  Filter::Util::Call                 1.59        0
	  IO::Compress::Bzip2               2.096        0
	  IO::Compress::Gzip                2.096        0
	  IO::Handle                         1.42     1.27
	  IO::Uncompress::Bunzip2           2.096        0
	  IO::Uncompress::Gunzip            2.096        0
	  IPC::Cmd                           1.04        0
	  Importer                          0.026    0.025
	  JSON::PP                           4.04        0
	  List::Util                         1.55     1.44
	  Long::Jump                     0.000001 0.000001
	  POSIX                              1.94        0
	  Scalar::Util                       1.55        0
	  Scope::Guard                       0.21        0
	  Symbol                             1.08        0
	  Sys::Hostname                      1.23        0
	  Term::Table                       0.015    0.015
	  Test2                          1.302181 1.302170
	  Test2::API                     1.302181 1.302170
	  Test2::Bundle::Extended        0.000138 0.000127
	  Test2::Event                   1.302181 1.302170
	  Test2::Event::V2               1.302181 1.302170
	  Test2::Formatter               1.302181 1.302170
	  Test2::Plugin::MemUsage        0.002003 0.002003
	  Test2::Plugin::UUID            0.002001 0.002001
	  Test2::Require::Module         0.000138 0.000127
	  Test2::Tools::AsyncSubtest     0.000138 0.000127
	  Test2::Tools::Subtest          0.000138 0.000127
	  Test2::Util                    1.302181 1.302170
	  Test2::Util::Term              0.000138 0.000127
	  Test2::V0                      0.000138 0.000127
	  Test::Builder                  1.302181 1.302170
	  Test::Builder::Formatter       1.302181 1.302170
	  Test::More                     1.302181 1.302170
	  Time::HiRes                      1.9764        0
	  base                               2.27        0
	  constant                           1.33        0
	  goto::file                        0.005    0.005
	  parent                            0.238        0

Perl module toolchain versions installed:
	Module Name                        Have
	CPANPLUS                         0.9908
	CPANPLUS::Dist::Build              0.90
	Cwd                                3.78
	ExtUtils::CBuilder             0.280234
	ExtUtils::Command                  7.48
	ExtUtils::Install                  2.18
	ExtUtils::MakeMaker                7.48
	ExtUtils::Manifest                 1.72
	ExtUtils::ParseXS                  3.40
	File::Spec                         3.78
	Module::Build                    0.4231
	Pod::Parser                           0
	Pod::Simple                        3.40
	Test2                          1.302181
	Test::Harness                      3.42
	Test::More                     1.302181
	version                          0.9928

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
    LANG = C.UTF-8
    LC_COLLATE = C
    NONINTERACTIVE_TESTING = 1
    PATH = /home/cpan/pit/thr/conf/perl-5.32.0/.cpanplus/5.32.0/build/sOxHMv4hqp/Test2-Harness-1.000042/blib/script:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    PERL5LIB = /home/cpan/pit/jail/NOg9ARIPgC/lib/perl5:/home/cpan/pit/thr/conf/perl-5.32.0/.cpanplus/5.32.0/build/sOxHMv4hqp/Test2-Harness-1.000042/blib/lib:/home/cpan/pit/thr/conf/perl-5.32.0/.cpanplus/5.32.0/build/sOxHMv4hqp/Test2-Harness-1.000042/blib/arch
    PERL5_CPANPLUS_IS_RUNNING = 18922
    PERL5_CPANPLUS_IS_VERSION = 0.9908
    PERL5_MINISMOKEBOX = 0.68
    PERL5_YACSMOKE_BASE = /home/cpan/pit/thr/conf/perl-5.32.0
    PERL_EXTUTILS_AUTOINSTALL = --defaultdeps
    PERL_LOCAL_LIB_ROOT = /home/cpan/pit/jail/NOg9ARIPgC
    PERL_MB_OPT = --install_base "/home/cpan/pit/jail/NOg9ARIPgC"
    PERL_MM_OPT = INSTALL_BASE=/home/cpan/pit/jail/NOg9ARIPgC
    PERL_MM_USE_DEFAULT = 1
    SHELL = /bin/bash
    TERM = screen

Perl special variables (and OS-specific diagnostics, for MSWin32):

    Perl: $^X = /home/cpan/pit/thr/perl-5.32.0/bin/perl
    UID:  $<  = 1001
    EUID: $>  = 1001
    GID:  $(  = 1001 1001
    EGID: $)  = 1001 1001


-------------------------------


--

Summary of my perl5 (revision 5 version 32 subversion 0) configuration:
   
  Platform:
    osname=linux
    osvers=5.4.43-1-lts
    archname=x86_64-linux-thread-multi
    uname='linux august 5.4.43-1-lts #2-alpine smp thu, 28 may 2020 20:13:48 utc x86_64 linux '
    config_args='-des -Dprefix=/home/cpan/pit/thr/perl-5.32.0 -Dusethreads'
    hint=recommended
    useposix=true
    d_sigaction=define
    useithreads=define
    usemultiplicity=define
    use64bitint=define
    use64bitall=define
    uselongdouble=undef
    usemymalloc=n
    default_inc_excludes_dot=define
    bincompat5005=undef
  Compiler:
    cc='cc'
    ccflags ='-D_REENTRANT -D_GNU_SOURCE -D_GNU_SOURCE -fwrapv -fno-strict-aliasing -pipe -fstack-protector-strong -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64'
    optimize='-O2'
    cppflags='-D_REENTRANT -D_GNU_SOURCE -D_GNU_SOURCE -fwrapv -fno-strict-aliasing -pipe -fstack-protector-strong'
    ccversion=''
    gccversion='9.3.0'
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
    ldflags =' -fstack-protector-strong -L/usr/local/lib'
    libpth=/usr/include/fortify /usr/lib /usr/local/lib /lib/../lib /usr/lib/../lib /lib
    libs=-lpthread -lgdbm -ldl -lm -lcrypt -lutil -lc -lgdbm_compat
    perllibs=-lpthread -ldl -lm -lcrypt -lutil -lc
    libc=/usr/lib/libc.a
    so=so
    useshrplib=false
    libperl=libperl.a
    gnulibc_version=''
  Dynamic Linking:
    dlsrc=dl_dlopen.xs
    dlext=so
    d_dlsymun=undef
    ccdlflags='-Wl,-E'
    cccdlflags='-fPIC'
    lddlflags='-shared -O2 -L/usr/local/lib -fstack-protector-strong'


Characteristics of this binary (from libperl): 
  Compile-time options:
    HAS_TIMES
    MULTIPLICITY
    PERLIO_LAYERS
    PERL_COPY_ON_WRITE
    PERL_DONT_CREATE_GVSV
    PERL_IMPLICIT_CONTEXT
    PERL_MALLOC_WRAP
    PERL_OP_PARENT
    PERL_PRESERVE_IVUV
    USE_64_BIT_ALL
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
    USE_REENTRANT_API
    USE_THREAD_SAFE_LOCALE
  Built under linux
  Compiled at Jun 21 2020 16:01:50
  %ENV:
    PERL5LIB="/home/cpan/pit/jail/NOg9ARIPgC/lib/perl5:/home/cpan/pit/thr/conf/perl-5.32.0/.cpanplus/5.32.0/build/sOxHMv4hqp/Test2-Harness-1.000042/blib/lib:/home/cpan/pit/thr/conf/perl-5.32.0/.cpanplus/5.32.0/build/sOxHMv4hqp/Test2-Harness-1.000042/blib/arch"
    PERL5_CPANPLUS_IS_RUNNING="18922"
    PERL5_CPANPLUS_IS_VERSION="0.9908"
    PERL5_MINISMOKEBOX="0.68"
    PERL5_YACSMOKE_BASE="/home/cpan/pit/thr/conf/perl-5.32.0"
    PERL_EXTUTILS_AUTOINSTALL="--defaultdeps"
    PERL_LOCAL_LIB_ROOT="/home/cpan/pit/jail/NOg9ARIPgC"
    PERL_MB_OPT="--install_base "/home/cpan/pit/jail/NOg9ARIPgC""
    PERL_MM_OPT="INSTALL_BASE=/home/cpan/pit/jail/NOg9ARIPgC"
    PERL_MM_USE_DEFAULT="1"
  @INC:
    /home/cpan/pit/jail/NOg9ARIPgC/lib/perl5/5.32.0/x86_64-linux-thread-multi
    /home/cpan/pit/jail/NOg9ARIPgC/lib/perl5/5.32.0
    /home/cpan/pit/jail/NOg9ARIPgC/lib/perl5/x86_64-linux-thread-multi
    /home/cpan/pit/jail/NOg9ARIPgC/lib/perl5
    /home/cpan/pit/thr/conf/perl-5.32.0/.cpanplus/5.32.0/build/sOxHMv4hqp/Test2-Harness-1.000042/blib/lib
    /home/cpan/pit/thr/conf/perl-5.32.0/.cpanplus/5.32.0/build/sOxHMv4hqp/Test2-Harness-1.000042/blib/arch
    /home/cpan/pit/thr/perl-5.32.0/lib/site_perl/5.32.0/x86_64-linux-thread-multi
    /home/cpan/pit/thr/perl-5.32.0/lib/site_perl/5.32.0
    /home/cpan/pit/thr/perl-5.32.0/lib/5.32.0/x86_64-linux-thread-multi
    /home/cpan/pit/thr/perl-5.32.0/lib/5.32.0
