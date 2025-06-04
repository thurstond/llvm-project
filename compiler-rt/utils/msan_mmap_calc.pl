#!/usr/bin/perl -w
use strict;
use diagnostics;


#
#
#       mmap_calc.pl : Prototyping tool for regenerating kMemoryLayout in
#                      compiler-rt/lib/msan/msan.h
#
#
#       Usage:
#           1) Modify @APP_REGIONS, app2shadow and/or shadow2origin.
#           2) Run this script, and paste the output into
#              compiler-rt/lib/msan/msan.h.
#           3) If you modified app2shadow or shadow2origin, you will also need
#              to update MEM_TO_SHADOW or SHADOW_TO_ORIGIN in msan.h, and
#              llvm/lib/Transforms/Instrumentation/MemorySanitizer.cpp.
#           4) Rebuild compiler-rt
#           5) If you modified app2shadow or shadow2origin, you will also need
#              to rebuild clang, libcxx, and possibly more. When in doubt,
#              perform a bootstrap build.
#
#


my $BYTES_PER_GB = (1024 ** 3);


my $SHADOW_XOR = 0;
my $ORIGIN_OFFSET = 0;
my @APP_REGIONS = ();

my $TRUE  = 1;
my $FALSE = 0;

if (1) {
    # Linux, aarch64 (2022: https://reviews.llvm.org/D137666)
    $SHADOW_XOR    = 0x0B00000000000;
    $ORIGIN_OFFSET = 0x0200000000000;

    @APP_REGIONS
        = (
           [0x0000000000000, 0x0100000000000, "10-13"],
           [0x0A00000000000, 0x0B00000000000, "14"],
           [0x0E00000000000, 0x0F00000000000, "15A"],
           [0x0F00000000000, 0x1000000000000, "15B"]
          );
} elsif (1) {
    # Linux, aarch64 (2015)
    $SHADOW_XOR    = 0x0600000000000;
    $ORIGIN_OFFSET = 0x0100000000000;

    @APP_REGIONS
        = (
           # 39-bit
           [0x0005000000000, 0x0006000000000, "1"],

           # 42-bit
           [0x0007000000000, 0x0008000000000, "2"],
           [0x000F000000000, 0x0010000000000, "3"],
           [0x0011000000000, 0x0012000000000, "4"],
           [0x0020000000000, 0x0021000000000, "5"],
           [0x002A000000000, 0x002B000000000, "6"],
           [0x002E000000000, 0x002F000000000, "7"],
           [0x003B000000000, 0x003C000000000, "8"],
           [0x003F000000000, 0x0040000000000, "9"],

           # 48-bit
           [0x0041000000000, 0x0042000000000, "10"],
           [0x0050000000000, 0x0051000000000, "11"],
           [0x0058000000000, 0x0059000000000, "12"],
           [0x0061000000000, 0x0062000000000, "13"],
           [0x0AAAAA0000000, 0x0AAAB00000000, "14"],
           [0x0FFFF00000000, 0x1000000000000, "15"]
          );
} else {
    # Linux, x86_64
    $SHADOW_XOR    = 0x500000000000;
    $ORIGIN_OFFSET = 0x100000000000;

    @APP_REGIONS
        = (
           [0x000000000000, 0x010000000000, "1"],
           [0x510000000000, 0x600000000000, "2"],
           [0x700000000000, 0x800000000000, "3"]
          );
}


sub mem2shadow ($) {
    my ($mem) = @_;

    return $mem ^ $SHADOW_XOR;
}


sub shadow2origin ($) {
    my ($shadow) = @_;

    return $shadow + $ORIGIN_OFFSET;
}


sub mem2origin ($) {
    my ($mem) = @_;

   return shadow2origin (mem2shadow ($mem));
}


sub printMapping ($$$$$) {
    my ($start, $end, $type, $id, $max) = @_;

    print "    {";
    print uc (sprintf "0x%013x", $start);
    print ", ";
    print uc (sprintf "0x%013x, ", $end);
    print "MappingDesc::" . uc ($type) . ", ";
    print "\"${type}";
    print "-" unless $id eq '';
    print "${id}\"";
    print "},";
    print " // ";
    print (($end - $start) / $BYTES_PER_GB);
    print "GB";
    print " (MAX)" if ($end - $start) == $max;
    print "\n";
}


# msan.h::addr_is_type
sub addrIsType ($$$) {
    my ($addr, $typeTarget, $sortedRegionsRef) = @_;

    foreach my $regionRef (@$sortedRegionsRef) {
        my ($start, $end, $type, $label) = @$regionRef;

        return $TRUE if    ($addr >= $start)
                        && ($addr < $end)
                        && ($type eq $typeTarget);
    }

    return $FALSE;
}


sub memIsApp ($$) {
    my ($addr, $sortedRegionsRef) = @_;

    return addrIsType ($addr, "app", $sortedRegionsRef);
}


sub memIsOrigin ($$) {
    my ($addr, $sortedRegionsRef) = @_;

    return addrIsType ($addr, "origin", $sortedRegionsRef);
}


sub memIsShadow ($$) {
    my ($addr, $sortedRegionsRef) = @_;

    return addrIsType ($addr, "shadow", $sortedRegionsRef);
}


# The maximum region size is limited by the *smaller* of the
# shadow or origin calculations.
my $maxRegionSize = $SHADOW_XOR;
$maxRegionSize = $ORIGIN_OFFSET if $ORIGIN_OFFSET < $maxRegionSize;

my $totalAppSize = 0;

my @allRegions = ();
foreach my $appRef (@APP_REGIONS) {
    my ($appStart, $appEnd, $appLabel) = @$appRef;

    push @allRegions, [$appStart, $appEnd, "app", $appLabel];
    $totalAppSize += ($appEnd - $appStart);

    my $shadowStart = mem2shadow ($appStart);
    my $shadowEnd   = mem2shadow ($appEnd - 1) + 1;
    die sprintf (  "Shadow mapping for (0x%x, 0x%x) is not contiguous (0x%x, 0x%x). "
                 . "Try splitting the app regions.\n", $appStart, $appEnd,
                 $shadowStart, $shadowEnd)
        unless ($shadowEnd == $shadowStart - $appStart + $appEnd);

    my $originStart = shadow2origin ($shadowStart);
    my $originEnd   = shadow2origin ($shadowEnd - 1) + 1;
    die "Origin mapping for ($appStart, $appEnd) is not contiguous. Try splitting the app regions.\n"
        unless ($originEnd == $originStart - $shadowStart + $shadowEnd);

    push @allRegions, [$shadowStart, $shadowEnd, "shadow", $appLabel];
    push @allRegions, [$originStart, $originEnd, "origin", $appLabel];
}

my @sortedValidRegions = sort {$$a [0] <=> $$b [0]} @allRegions;
my $prevEnd = 0;

my @sortedRegions = @sortedValidRegions;

# Augment @sortedRegions with "invalid" (mprotected) regions between
# the app/shadow/origin regions.
foreach my $i (0 .. $#sortedRegions) {
    my ($start, $end, $type, $label) = @{$sortedRegions [$i]};

#    if ($i == 0 && $start != 0) {
#        printMapping (0, $start, "invalid", "", $maxRegionSize);
#    }

    if ($i > 0) {
        if ($start == $prevEnd) {
#            print "    // Regions are adjacent\n";
        } elsif ($start < $prevEnd) {
#            printf ("    // ERROR: Regions are overlapping (start: 0x%x; prevEnd: 0x%x)\n",
#                    $start, $prevEnd);
        } else {
            push @sortedRegions, [$prevEnd, $start, "invalid", ""];
        }
    }

    $prevEnd = $end;
}

@sortedRegions = sort {$$a [0] <=> $$b [0]} @sortedRegions;
foreach my $i (0 .. $#sortedRegions) {
    my ($start, $end, $type, $label) = @{$sortedRegions [$i]};
    printMapping ($start, $end, $type, $label, $maxRegionSize);

    # Assertions from msan_linux.cpp::CheckMemoryLayoutSanity
    die "Start $start is not less than end $end\n" unless $start < $end;

    # Relax the assertion because we do not necessarily generate a region
    # starting at zero
    die   "prevEnd " . sprintf ("0x%x", $prevEnd) . " is not equal to start "
        . sprintf ("0x%x", "$start\n")
        unless ($prevEnd == $start) || ($i == 0);

    die unless addrIsType ($start, $type, \@sortedRegions);
    die "Mid point 0x" . sprintf ("%x", ($start + $end) / 2) . " is not $type!\n"
        unless addrIsType (($start + $end) / 2, $type, \@sortedRegions);
    die unless addrIsType ($end - 1, $type, \@sortedRegions);

    if ($type eq 'app') {
        foreach my $addr ($start, ($start + $end) / 2, $end - 1) {
            die   "mem2shadow of 0x" . sprintf ("%0x", $addr) . " == "
                . sprintf ("0x%x is not a shadow! ", mem2shadow ($addr))
                . sprintf ("(0x%0x, 0x%0x)\n", $start, $end)
                unless memIsShadow (mem2shadow ($addr), \@sortedRegions);
            die unless memIsOrigin (mem2origin ($addr), \@sortedRegions);
            die unless    mem2origin ($addr)
                       == shadow2origin (mem2shadow ($addr));
        }
    }

    $prevEnd = $end;
}

print "\n";
print "Shadow XOR:    ";
print uc (sprintf "0x%013x", $SHADOW_XOR);
print " (" . ($SHADOW_XOR / $BYTES_PER_GB) . "GB)\n";
print "Origin offset: ";
print uc (sprintf "0x%013x", $ORIGIN_OFFSET);
print " (" . ($ORIGIN_OFFSET / $BYTES_PER_GB) . "GB)\n";
print "\n";
print "Total size of app regions: " . ($totalAppSize / $BYTES_PER_GB) . "GB\n";
print "\n";
print "N.B. the trailing region is not printed (this depends on the VMA size).\n";
