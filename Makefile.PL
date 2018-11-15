use 5.010;
use strict;
use warnings;
use version;
use ExtUtils::MakeMaker;
use File::Slurp;
#use File::Spec;

# === Code-based configuration ============================================

# Ignore *.c so that EUMM doesn't add build rules for them to Makefile
# Thanks to https://www.perlmonks.org/?node_id=982933 by Anonymous Monk
sub MY::libscan {
    my( $mm, $file ) = @_;
    return if $file =~  /\.c$/; # SKIP
    return $file;
}

# Hijack the Makefile so that our build steps run instead of EUMM's.
sub MY::post_initialize {
    my $self = shift;

    # Get the name of the default target
    my $tgt = $self->makemakerdflt_target;
    $tgt =~ s/^(\w+).*/$1/s;

    # Get our actual Makefile, which must not use the "all" target
    my $custom = read_file('Makefile', err_mode => 'carp');
    my $custom_tgt = 'custom';
    $custom_tgt = $1 if $custom =~ m/^(\w+):/m;

    # Put our Makefile first.
    return <<EOT;
very_first_target: $custom_tgt
eumm: $tgt

test :: $custom_tgt

$custom
EOT

} # MY::post_initialize

# === Write the makefile ==================================================

WriteMakefile(
    #FIRST_MAKEFILE   => File::Spec->devnull,
        # Can't do this because EUMM tries to rename the generated file to
        # $FIRST_MAKEFILE.
    FIRST_MAKEFILE   => 'Makefile.dummy',
    NAME             => 'NonPerl::DoNotSelfHost',
    AUTHOR           => q{Christopher White <cxwembedded@gmail.com>},
    VERSION          => qv(0.0.1),
    ABSTRACT         => 'Testing support for do-not-self-host',
    LICENSE          => 'open_source',  # ISC, in fact
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'File::Slurp' => '0',
        #'File::Spec' => '0',
        'version' => '0.77',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    TEST_REQUIRES => {
        'Test::Harness' => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/cxw42/do-not-self-host.git',
                web  => 'https://github.com/cxw42/do-not-self-host',
            },
        },
    },
);