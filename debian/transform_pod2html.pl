#!/usr/bin/perl
use strict;
use Carp;
use File::Find;
use File::Spec;
use Pod::Html;
use File::Path qw(make_path);

# dependencies
use Readonly;
use autodie qw(open close);
use HTML::Template;

Readonly my $CUR_DIR => $ARGV[0];
Readonly my $SRC_DIR => $ARGV[1];
Readonly my $DEST_DIR => $ARGV[2];
croak "No source directory: $SRC_DIR" if not -d $SRC_DIR;
croak "No destination directory: $DEST_DIR" if not -d $DEST_DIR;

# This data structure will end up being
# a hierarchical index of the HTML formats of 
# the pod in the form expected by HTML::Template.
my %data = (links=>[],sections=>[]);

find( \&transform_pod2html, $SRC_DIR );
my $template = HTML::Template->new(filename=>"$CUR_DIR/debian/index.tmpl", die_on_bad_params=>0);
$template->param(%data);
open my $fh,'>', "$CUR_DIR/$DEST_DIR/index.html";
print {$fh} $template->output;
close$fh;

exit(0);

sub transform_pod2html {
    return if $File::Find::dir =~ m{/\.svn};
    my $name = $_;
    return if $name eq '.svn';
    return if $name !~ m{\.pod$};
    my ($v, $directories, $file) = File::Spec->splitpath($File::Find::name);
    $name =~ s{\.pod$}{\.html};
    my @dirs = File::Spec->splitdir($directories);
    shift @dirs; # should be 'docs'
    my $newdir = File::Spec->catdir($CUR_DIR, $DEST_DIR, @dirs);
    make_path($newdir, {verbose=>1});
    my $newfile = File::Spec->catfile($newdir, $name);
    my $oldfile = File::Spec->catfile($CUR_DIR, $File::Find::name);
    print "$File::Find::name -> $newfile\n";
    pod2html("--infile=$oldfile", "--outfile=$newfile");
    my $new_url_dir = File::Spec->catdir(
        'cgi-bin', 'dwww', 'usr', 'share', 'doc', 'libapache2-mod-perl2-doc',
        @dirs
    );    
    index_file($name, "/$new_url_dir/$name", @dirs);
    return;
}

sub index_file {
    my $name = shift;
    my $newfile = shift;
    my @dirs = @_;
    my $ptr = \%data;
    foreach my $d (@dirs) {
        last if $d eq '';
        $ptr = find_section($ptr, $d);
    }
    push @{$ptr->{links}}, {href=>$newfile,text=>$name};
    return;
}

sub find_section {
    my $ptr = shift;
    my $dir = shift;
    my @sections = @{$ptr->{sections}};
    foreach my $s (@sections) {
        return $s if $s->{title} eq $dir;
    }
    my %ldata = (title=>$dir,links=>[],sections=>[]);
    push @{$ptr->{sections}}, \%ldata;
    return \%ldata;
}
