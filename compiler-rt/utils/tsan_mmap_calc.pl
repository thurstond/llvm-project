#!/usr/bin/perl -w
use strict;
use diagnostics;


my $TRUE  = 1;
my $FALSE = 0;

my $BYTES_PER_GB = (1024 ** 3);

my $kShadowCnt = 4;
my $kShadowCell = 8;
my $kShadowSize = 4;
my $kShadowMultiplier = $kShadowSize * $kShadowCnt / $kShadowCell;

my $kMetaShadowCell = 8;
my $kMetaShadowSize = 4;

my $kCompressedAddrBits = 44;

my $TEST_QUALITY = 256;
$TEST_QUALITY = 65536;

my $configuration = "";

my $kBrokenMapping        = $FALSE;
my $kBrokenReverseMapping = $FALSE;
my $kBrokenLinearity      = $FALSE;

# Unsupported
# my $kBrokenAliasedMetas   = $FALSE;

my ($kLoAppMemBeg, $kLoAppMemEnd,
    $kShadowBeg, $kShadowEnd,
    $kMetaShadowBeg, $kMetaShadowEnd,
    $kMidAppMemBeg, $kMidAppMemEnd,
    $kHeapMemBeg, $kHeapMemEnd,
    $kHiAppMemBeg, $kHiAppMemEnd,
    $kShadowMsk, $kShadowXor, $kShadowAdd,
    $kVdsoBeg);
my ($kMetaShadowOr);
my ($kMetaShadowMskOverride);

my $configuration = "x86_64 (47-bit userspace, updated)";
my %parameters
    = (
           "x86_64 (no low app region)"
       => {
           kMetaShadowOr => 0x000000000000,
#    $kMetaShadowEnd => 0x340000000000;

#    $kShadowBeg     => 0x010000000000;
#    $kShadowEnd     => 0x100000000000;

           kLoAppMemBeg   => 0x008000000000,
           kLoAppMemEnd   => 0x008000000000,

           kMidAppMemBeg  => 0x550000000000,
           kMidAppMemEnd  => 0x568000000000,

           kHeapMemBeg    => 0x7b0000000000,
           kHeapMemEnd    => 0x7c0000000000,

           kHiAppMemBeg   => 0x7e8000000000,
           kHiAppMemEnd   => 0x800000000000,

           kShadowMsk => 0x780000000000,
           kShadowXor => 0x000000000000,
           kShadowAdd => 0x000000000000
          },

          "x86_64 (47-bit userspace, updated)"
       => {
           kMetaShadowOr  => 0x300000000000,
#    $kMetaShadowEnd => 0x340000000000;

#    $kShadowBeg     => 0x010000000000;
#    $kShadowEnd     => 0x100000000000;

           kLoAppMemBeg   => 0x000000001000,
           kLoAppMemEnd   => 0x020000000000,

           kMidAppMemBeg  => 0x550000000000,
           kMidAppMemEnd  => 0x5a0000000000,

           kHeapMemBeg    => 0x720000000000,
           kHeapMemEnd    => 0x730000000000,

           kHiAppMemBeg   => 0x7a0000000000,
           kHiAppMemEnd   => 0x800000000000,

           kShadowMsk     => 0x700000000000,
           kShadowXor     => 0x000000000000,
           kShadowAdd     => 0x100000000000

#    $kVdsoBeg       => 0xf000000000000000;
          },
           "aarch64, 48-bit VMA (prior to 1/9/23)"
       => {
           kLoAppMemBeg   => 0x0000000001000,
           kLoAppMemEnd   => 0x0000200000000,

#    $kShadowBeg     => 0x0001000000000;
#    $kShadowEnd     => 0x0002000000000;

           kMetaShadowOr => 0x0005000000000,
#    $kMetaShadowEnd => 0x0006000000000;

           kMidAppMemBeg  => 0x0aaaa00000000,
           kMidAppMemEnd  => 0x0aaaf00000000,

           kHeapMemBeg    => 0x0ffff00000000,
           kHeapMemEnd    => 0x0ffff00000000,

           kHiAppMemBeg   => 0x0ffff00000000,
           kHiAppMemEnd   => 0x1000000000000,

           kShadowMsk     => 0x0fff800000000,
           kShadowXor     => 0x0000800000000,
           kShadowAdd     => 0x0000000000000

#    $kVdsoBeg       => 0xffff000000000;
          },

    # 12/27/22, ~50 failures
    # Compatibility with pointer compression
           "aarch64, 48-bit VMA (as of 1/9/23)"
       => {
           kLoAppMemBeg   => 0x0000000001000,
           kLoAppMemEnd   => 0x00A0000000000,

#    $kShadowBeg     => 0x0001000000000;
#    $kShadowEnd     => 0x0002000000000;

           kMetaShadowOr => 0x0800000000000,
#    $kMetaShadowEnd => 0x0006000000000;

           kMidAppMemBeg  => 0x0aaaa00000000,
           kMidAppMemEnd  => 0x0ac0000000000,

           kHeapMemBeg    => 0x0fc0000000000,
           kHeapMemEnd    => 0x0fc0000000000,

           kHiAppMemBeg   => 0x0fc0000000000,
           kHiAppMemEnd   => 0x1000000000000,

           kShadowMsk     => 0x0C00000000000,
           kShadowXor     => 0x0200000000000,
           kShadowAdd     => 0x0000000000000

#    $kVdsoBeg       => 0xffff000000000;
          },

           "x86_64 (56-bit userspace)"
       => {
           kMetaShadowOr => 0x300000000000,
#    $kMetaShadowEnd => 0x340000000000;

#    $kShadowBeg     => 0x010000000000;
#    $kShadowEnd     => 0x100000000000;

           kLoAppMemBeg   => 0x000000001000,
           kLoAppMemEnd   => 0x008000000000,

           kMidAppMemBeg  => 0x550000000000,
           kMidAppMemEnd  => 0x568000000000,

           kHeapMemBeg    => 0x7b0000000000,
           kHeapMemEnd    => 0x7c0000000000,

           kHiAppMemBeg   => 0x7e8000000000,
           kHiAppMemEnd   => 0x808000000000,

           kShadowMsk => 0x780000000000,
           kShadowXor => 0x040000000000,
           kShadowAdd => 0x000000000000

#    $kVdsoBeg       => 0xf000000000000000;
          },

           "x86_64 (47-bit userspace, classic)"
       => {
           kMetaShadowOr => 0x300000000000,
#           kMetaShadowEnd => 0x340000000000,

#           kShadowBeg     => 0x010000000000,
#           kShadowEnd     => 0x100000000000,

           kLoAppMemBeg   => 0x000000001000,
           kLoAppMemEnd   => 0x008000000000,

           kMidAppMemBeg  => 0x550000000000,
           kMidAppMemEnd  => 0x568000000000,

           kHeapMemBeg    => 0x7b0000000000,
           kHeapMemEnd    => 0x7c0000000000,

           kHiAppMemBeg   => 0x7e8000000000,
           kHiAppMemEnd   => 0x800000000000,

           kShadowMsk => 0x780000000000,
           kShadowXor => 0x040000000000,
           kShadowAdd => 0x000000000000,

#           kVdsoBeg       => 0xf000000000000000,
          },

           "aarch64, 48-bit VMA - no low app region"
       => {
           kLoAppMemBeg   => 0x0001000000000, # Kludge
           kLoAppMemEnd   => 0x0001000000000,

#           kLoAppMemBeg   => 0x0000000001000,
#           kLoAppMemEnd   => 0x00A0000000000,

#           kShadowBeg     => 0x0001000000000,
#           kShadowEnd     => 0x0002000000000,

           kMetaShadowOr => 0x0000000000000,
#           kMetaShadowEnd => 0x0006000000000,

           kMidAppMemBeg  => 0x0aaaa00000000,
           kMidAppMemEnd  => 0x0ac0000000000,

           kHeapMemBeg    => 0x0fc0000000000,
           kHeapMemEnd    => 0x0fc0000000000,

           kHiAppMemBeg   => 0x0fc0000000000,
           kHiAppMemEnd   => 0x1000000000000,

           kShadowMsk     => 0x0D00000000000,
           kShadowXor     => 0x0000000000000,
           kShadowAdd     => 0x0000000000000

#           kMetaShadowMskOverride => 0x0D00000000000, # Or 0x0B

#           kVdsoBeg       => 0xffff000000000,
          },

           "Apple Aarch64"
       => {
           kLoAppMemBeg   => 0x0100000000,
           kLoAppMemEnd   => 0x0200000000,
           kHeapMemBeg    => 0x0200000000,
           kHeapMemEnd    => 0x0300000000,

#           kShadowBeg     => 0x0400000000,
#           kShadowEnd => 0x0800000000,
           kMetaShadowOr => 0x0d00000000,
#           kMetaShadowEnd => 0x0e00000000,
           kHiAppMemBeg   => 0x0fc0000000,
           kHiAppMemEnd   => 0x0fc0000000,

           kShadowMsk => 0x0,
           kShadowXor => 0x0,
           kShadowAdd => 0x0200000000,

#            kVdsoBeg       => 0x7000000000000000,

           kMidAppMemBeg => 0,
           kMidAppMemEnd => 0
          },
           "PowerPC64, 44-bit VMA"
       => {
           kBrokenMapping => $TRUE,
           kBrokenReverseMapping => $TRUE,
           kBrokenLinearity => $TRUE,

           kLoAppMemBeg   => 0x000000000100,
           kLoAppMemEnd   => 0x000100000000,

           kMetaShadowOr => 0x0b0000000000,

           kMidAppMemBeg  => 0,
           kMidAppMemEnd  => 0,

           kHeapMemBeg    => 0x0f0000000000,
           kHeapMemEnd    => 0x0f5000000000,

           kHiAppMemBeg   => 0x0f6000000000,
           kHiAppMemEnd   => 0x100000000000,

           kShadowMsk     => 0x0f0000000000,
           kShadowXor     => 0x002100000000,
           kShadowAdd     => 0x000000000000

#           kVdsoBeg       => 0x3c0000000000000,
          },
           "aarch64, 42-bit VMA"
       => {
           kLoAppMemBeg   => 0x00000001000,
           kLoAppMemEnd   => 0x02000000000,

           kMetaShadowOr => 0x20000000000,

           kMidAppMemBeg  => 0x2aa00000000,
           kMidAppMemEnd  => 0x2c000000000,

           kHeapMemBeg    => 0x3c000000000,
           kHeapMemEnd    => 0x3f000000000,

           kHiAppMemBeg   => 0x3f000000000,
           kHiAppMemEnd   => 0x3ffffffffff,

           kShadowMsk     => 0x38000000000,
           kShadowXor     => 0x08000000000,
           kShadowAdd     => 0x00000000000

#           kVdsoBeg       => 0x37f00000000,
          },
           "aarch64, 39-bit VMA (updated)"
       => {
           kLoAppMemBeg   => 0x0000001000,
           kLoAppMemEnd   => 0x0500000000,

           kMetaShadowOr => 0x4000000000,

           kMidAppMemBeg  => 0x5500000000,
           kMidAppMemEnd  => 0x5a00000000,

           kHeapMemBeg    => 0x7a00000000,
           kHeapMemEnd    => 0x7d00000000,

           kHiAppMemBeg   => 0x7d00000000,
           kHiAppMemEnd   => 0x7fffffffff,

           kShadowMsk     => 0x7000000000,
           kShadowXor     => 0x1000000000,
           kShadowAdd     => 0x0000000000

#           kVdsoBeg       => 0x7f00000000,
          },
           "aarch64, 39-bit VMA"
       => {
           kLoAppMemBeg   => 0x0000001000,
           kLoAppMemEnd   => 0x0100000000,

           kMetaShadowOr => 0x3000000000,

           kMidAppMemBeg  => 0x5500000000,
           kMidAppMemEnd  => 0x5600000000,

           kHeapMemBeg    => 0x7c00000000,
           kHeapMemEnd    => 0x7d00000000,

           kHiAppMemBeg   => 0x7e00000000,
           kHiAppMemEnd   => 0x7fffffffff,

           kShadowMsk     => 0x7800000000,
           kShadowXor     => 0x0200000000,
           kShadowAdd     => 0x0000000000

#           kVdsoBeg       => 0x7f00000000,
          }
      );

if (! defined $parameters {$configuration}) {
    print "Known configurations:\n";
    foreach my $config (sort keys %parameters) {
        print "- $config\n";
    }
    print "\n";
    die "Unknown configuration '$configuration'!\n";
}

my ($kLoAppMemBeg, $kLoAppMemEnd,
    $kMetaShadowOr,
    $kMidAppMemBeg, $kMidAppMemEnd,
    $kHeapMemBeg, $kHeapMemEnd,
    $kHiAppMemBeg, $kHiAppMemEnd,
    $kShadowMsk, $kShadowXor, $kShadowAdd);
foreach my $param (qw (kLoAppMemBeg kLoAppMemEnd
                       kMetaShadowOr
                       kMidAppMemBeg kMidAppMemEnd
                       kHeapMemBeg kHeapMemEnd
                       kHiAppMemBeg kHiAppMemEnd
                       kShadowMsk kShadowXor kShadowAdd)) {
    die "Parameter $param not defined for '$configuration'!\n"
        unless defined $parameters {$configuration}{$param};
    eval ("\$$param = \$parameters {\$configuration}{\$param}");
}

#sub not64 ($) {
#    my ($x) = @_;
#
#    return (1 << 64 - $x);
#}


# compiler-rt/lib/tsan/rtl/tsan_platform.h
sub memToShadow ($) {
    my ($mem) = @_;

    return (  (  ($mem & (~($kShadowMsk | ($kShadowCell - 1))))
               ^ $kShadowXor)
            * $kShadowMultiplier
            + $kShadowAdd);
}

sub memToMeta ($) {
    my ($mem) = @_;

    return (  (  ($mem & (~($kMetaShadowMskOverride | ($kMetaShadowCell - 1))))
               / $kMetaShadowCell * $kMetaShadowSize)
            | $kMetaShadowOr);
}


sub isAppMem ($) {
    my ($mem) = @_;

    return (   ($mem >= $kHeapMemBeg && $mem <= $kHeapMemEnd)
            || ($mem >= $kMidAppMemBeg && $mem <= $kMidAppMemEnd)
            || ($mem >= $kLoAppMemBeg && $mem <= $kLoAppMemEnd)
            || ($mem >= $kHiAppMemBeg && $mem <= $kHiAppMemEnd));
}


sub isShadowMem ($) {
    my ($mem) = @_;

    return ($mem >= $kShadowBeg) && ($mem <= $kShadowEnd);
}


sub isMetaMem ($) {
    my ($mem) = @_;

    return ($mem >= $kMetaShadowBeg) && ($mem <= $kMetaShadowEnd);
}


sub shadowToMem ($) {
    my ($sp) = @_;

    return 0 if (! isShadowMem ($sp));

    my $p = (($sp - $kShadowAdd) / $kShadowMultiplier) ^ $kShadowXor;

    if (   ($p >= $kLoAppMemBeg)
        && ($p < $kLoAppMemEnd) # Open interval
        && (memToShadow ($p) == $sp)) {
        return $p;
    }
    if ($kMidAppMemBeg) {
        my $p_mid = $p + ($kMidAppMemBeg & $kShadowMsk);
        if (   ($p_mid >= $kMidAppMemBeg)
            && ($p_mid < $kMidAppMemEnd) # Open interval
            && (memToShadow ($p_mid) == $sp)) {
            return $p_mid;
        }
    }

    return $p | $kShadowMsk;
}


sub bitScanForward64 ($) {
    my ($x) = @_;

    my $i = 0;
    while ($i < 64) {
        return $i if ($x % 2 == 1);

        $x = $x >> 1;
        $i ++;
    }

    die;
}


sub leastSignificantSetBitIndex ($) {
    my ($indicator) = @_;

    return bitScanForward64 ($indicator);
}


# This undoes "pointer compression", which only retained the lower
# $kCompressedAddrBits bits of the pointer.
sub restoreAddrImpl ($) {
    my ($addr) = @_;

    my @ranges
        = (
           [$kLoAppMemBeg, $kLoAppMemEnd, "Low"],
           [$kMidAppMemBeg, $kMidAppMemEnd, "Mid"],
           [$kHiAppMemBeg, $kHiAppMemEnd, "High"],
           [$kHeapMemBeg, $kHeapMemEnd, "Heap"]
          );

    # 1111 + 40 zero bits
    # Indicator was changed from 3 bits to 4 bits in https://reviews.llvm.org/D145214
    my $indicator = 0x0f0000000000;
    my $ind_lsb = 1 << leastSignificantSetBitIndex ($indicator);

    my @matches = ();
    foreach my $i (0 .. $#ranges) {
        my ($beg, $end, $label) = @{$ranges [$i]};

        next if ($beg == $end);

        for (my $p = $beg; $p < $end; $p = roundDown ($p + $ind_lsb, $ind_lsb)) {
            if (($addr & $indicator) == ($p & $indicator)) {
#                printf "[0x%x, 0x%x] p: 0x%x (masked: 0x%x), addr: 0x%x (masked: 0x%x)\n",
#                       $beg, $end, $p, ($p & $indicator), $addr, ($addr & $indicator);

                # tsan_platform.h will return the first matching address, even
                # if there are actually multiple matches. We choose to log them
                # and abort in the case of ambiguous matches.
                #
                # If the address space is smaller than the indicator (e.g.,
                # 39-bit aarch64), there will be multiple matches, but it won't
                # actually be ambiguous - address space compression will have
                # truncated the top bits, which are all zero in each of the
                # app regions.
                my $restored = $addr | ($p & ~($ind_lsb - 1));

                if (@matches == 0 || ($restored != $matches [0])) {
                    push @matches, [$restored, $beg, $end, $label];

                    die "Compress/restore addr function is not invertible!\n"
                        unless compressAddr ($restored) == $addr;
                }
            }
        }
    }

    if (@matches == 1) {
        return $matches [0][0];
    } elsif (@matches == 0) {
        die "No matches found by restoreAddrImpl\n";
    } else {
        printf "Indicator: 0x%x\n", $indicator;
        printf "ind_lsb:   0x%x\n", $ind_lsb;
        print "\n";

        printf "Truncated address 0x%012x can map to:\n", $addr;
        foreach my $matchRef (@matches) {
            my ($match, $beg, $end, $label) = @$matchRef;
            printf "- 0x%012x (0x%x, 0x%x: %s)\n", $match, $beg, $end, $label;

            unless ($match >= $beg && $match <= $end) {
                print "  Note: restored address lies outside the stated region.\n";
                print "  Pointer compression leads to equivalence classes.\n";
            }
        }

        print "WARNING: multiple matches found by restoreAddrImpl\n";

        return $matches [0][0];
    }
}


sub compressAddr ($) {
    my ($addr) = @_;

    return $addr & ((1 << $kCompressedAddrBits) - 1);
}


sub roundDown ($$) {
    my ($number, $multiple) = @_;

    die "$number\n" unless $number >= 0;

    return $multiple * int ($number / $multiple);
}


sub printMappings ($) {
    my ($mappingsRef) = @_;

    my @sortedMappings = sort {$$a [0] <=> $$b [0]} @$mappingsRef;

    my $overlap = $FALSE;
    foreach my $i (0 .. $#sortedMappings) {
         my ($start, $end, $label) = @{$sortedMappings [$i]};

         printf "%sBeg = 0x%x\n", $label, $start;
         printf "%sEnd = 0x%x // %dGB", $label, $end,  ($end - $start) / $BYTES_PER_GB + 0.001;
         # Due to the stride, we can't simply round up by adding one byte to
         # $end - $start

        if ($i < $#sortedMappings) {
            my ($nextStart, $nextEnd, $nextLabel) = @{$sortedMappings [$i + 1]};

            if ($end > $nextStart) {
                print " *OVERLAP*\n";
                $overlap = $TRUE;
            } else {
                print "\n";
                printf "// GAP: %dGB\n", ($nextStart - $end) / $BYTES_PER_GB;
            }
        } else {
            print "\n";
        }
    }

    return $overlap;
}


sub tryProtectRange ($$$$) {
    my ($beg, $end, $begLabel, $endLabel) = @_;

    die (sprintf "0x%x is not before 0x%x (%s %s)\n", $beg, $end, $begLabel, $endLabel)
        unless $beg <= $end;
}

$kMetaShadowMskOverride = $kShadowMsk unless defined $kMetaShadowMskOverride;

# shadowToMem assumes that kShadowMsk does nothing at all to the low app
# region, while having maximum impact on the high app region. This
# assumption holds if the low app region starts at zero, while the high
# app region starts at the top of the address space.
die "Need to change shadowToMem here and in tsan library (low app incompatible)!\n"
    unless (    (($kLoAppMemBeg & ~$kShadowMsk) == ($kLoAppMemBeg))
            && ((($kLoAppMemEnd - 1) & ~$kShadowMsk) == ($kLoAppMemEnd - 1)))
           || ($kLoAppMemBeg == $kLoAppMemEnd);
die "Need to change shadowToMem here and in tsan library (high app incompatible)!\n"
    unless (   (($kHiAppMemBeg | $kShadowMsk) == ($kHiAppMemBeg))
            && ((($kHiAppMemEnd - 1) | $kShadowMsk) == ($kHiAppMemEnd - 1)))
           || ($kHiAppMemBeg == $kHiAppMemEnd);

my @memMappings = (
                   [$kLoAppMemBeg,  $kLoAppMemEnd,  "kLoAppMem"],
                   [$kMidAppMemBeg, $kMidAppMemEnd, "kMidAppMem"],
                   [$kHiAppMemBeg,  $kHiAppMemEnd,  "kHiAppMem"],

                   [$kHeapMemBeg,   $kHeapMemEnd,   "kHeapMem"],
                  );

die "\$kShadowBeg is an output, not an input parameter\n"
    if defined $kShadowBeg;
die "\$kShadowEnd is an output, not an input parameter\n"
    if defined $kShadowEnd;
die "\$kMetaShadowEnd is an output, not an input parameter\n"
    if defined $kMetaShadowEnd;
die "This script cannot handle kVdsoBeg\n"
    if defined $kVdsoBeg;

print "# Configuration: $configuration\n";

my ($shadowMin, $shadowMax);
my ($metaMin, $metaMax);

my @allMappings = ();

my $ignoreErrors = $FALSE;
#$ignoreErrors = $TRUE;

# We don't want shadows for two apps overlapping within the unified shadow
# (likewise, with metas) - we therefore need to keep track of the individual
# shadow regions.
my @fineGrainedMappings = ();
foreach my $mappingRef (@memMappings) {
     my ($start, $end, $label) = @$mappingRef;

     if ($start == $end) {
         print "# Dropping empty region $label\n";
     } else {
         my $shadowStart = memToShadow ($start);
         my $shadowEnd   = memToShadow ($end - 1) + 1; # Not quite correct

         die (sprintf "Monotonicity violated: Start: 0x%012x; End: 0x%012x; Shadow start: 0x%012x; shadow end: 0x%012x\n",
                      $start, $end, $shadowStart, $shadowEnd)
             unless $ignoreErrors || $kBrokenLinearity || ($shadowEnd >= $shadowStart);

         if ((! defined $shadowMin) || ($shadowStart < $shadowMin)) {
             $shadowMin = $shadowStart;
         }
         if ((! defined $shadowMax) || ($shadowEnd > $shadowMax)) {
             $shadowMax = $shadowEnd;
         }

         my $metaStart = memToMeta ($start);
         my $metaEnd   = memToMeta ($end - 1) + 1; # Not quite correct

         die (sprintf   "Meta start appears before meta end!\n"
                      . "Meta start: 0x%012x; meta end: 0x%012x\n",
                      $metaStart, $metaEnd)
             unless $ignoreErrors || ($metaEnd >= $metaStart);

         if ((! defined $metaMin) || ($metaStart < $metaMin)) {
             $metaMin = $metaStart;
         }
         if ((! defined $metaMax) || ($metaEnd > $metaMax)) {
             $metaMax = $metaEnd;
         }

         push @allMappings, [$start, $end, $label];
         push @fineGrainedMappings, [$start, $end, $label];

         printf "# [0x%x, 0x%x] (%dGB): %s",
                $shadowStart,
                $shadowEnd,
                ($shadowEnd - $shadowStart) / $BYTES_PER_GB + 0.001,
                "Shadow for $label\n";
         printf "# [0x%x, 0x%x] (%dGB): %s",
                $metaStart,
                $metaEnd,
                ($metaEnd - $metaStart) / $BYTES_PER_GB + 0.001,
                "Meta for $label\n";

         push @fineGrainedMappings, [$shadowStart, $shadowEnd, "Shadow for $label"];
         push @fineGrainedMappings, [$metaStart, $metaEnd, "Meta for $label"];
     }
}

push @allMappings, [$shadowMin, $shadowMax, "kShadow"];
push @allMappings, [$metaMin, $metaMax, "kMetaShadow"];

print "\n";

$kShadowBeg = $shadowMin;
$kShadowEnd = $shadowMax;

# Low region starts at 0x1000 so it's not exact
#die (sprintf "%x %x\n", $kMetaShadowBeg, $metaMin) unless $kMetaShadowBeg == $metaMin;
$kMetaShadowBeg = $metaMin;
$kMetaShadowEnd = $metaMax;

foreach my $mappingRef (@memMappings) {
     my ($start, $end, $label) = @$mappingRef;

     if ($start == $end) {
         print "# Dropping empty region $label\n";
     } else {
         my $i = 0;

         # compiler-rt/lib/tsan/tests/unit/tsan_shadow_test.cpp::TestRegion
         if (1) {
             my $prev = 0;
             for (my $p0 = $start; $p0 <= $end; $p0 += ($end - $start) / $TEST_QUALITY) {
                 foreach (my $x = -$kShadowCell; $x <= $kShadowCell; $x += $kShadowCell) {
                     my $p = roundDown ($p0 + $x, $kShadowCell);

                     next if $p < $start || $p >= $end;

                     my $s = memToShadow ($p);
                     my $m = memToMeta ($p);
                     my $r = shadowToMem ($s);

                     die (sprintf ("p = 0x%012x is not app memory!\n", $p))
                         unless isAppMem ($p);
                     die "kBrokenMapping\n" unless $kBrokenMapping || isShadowMem ($s);
                     die (sprintf ("p = 0x%012x is not meta memory!\n", $p))
                         unless isMetaMem ($m);

                     die (sprintf ("p = 0x%012x, compressAddr(p) = 0x%012x, restoreAddr = 0x%012x\n",
                                   $p, compressAddr ($p), restoreAddrImpl (compressAddr ($p)))),
                         unless $p == restoreAddrImpl (compressAddr ($p));

                     die (sprintf "kBrokenReverseMapping: p=0x%012x, s=0x%012x, r=0x%012x\n",
                                  $p, $s, $r) unless $kBrokenReverseMapping || ($p == $r);

                     # kBrokenLinearity test
                     if ($prev && !$kBrokenLinearity) {
                         my $prev_s = memToShadow ($prev);
                         my $prev_m = memToMeta ($prev);

                         die (sprintf "Monotonicity violated for 0x%x (shadow 0x%x; prev 0x%x; prev shadow: 0x%x)\n",
                                      $p, $s, $prev, $prev_s)
                             unless $kBrokenLinearity || (($s - $prev_s) == ($p - $prev) * $kShadowMultiplier);

                         # We multiply by kMetaShadowSize, per the MemToMetaImpl formula.
                         # tsan_shadow_test.cpp omits that multiplication, because they are using pointer
                         # arithmetic with a stride of four bytes.
                         die (sprintf "Monotonicity violated for 0x%x (meta 0x%x; prev 0x%x; prev meta: 0x%x)\n",
                                      $p, $m, $prev, $prev_m)
                             unless ($m - $prev_m) == ($p - $prev) / $kMetaShadowCell * $kMetaShadowSize;
                     }

                     $prev = $p;

                     $i ++;
                 }
             }
         }

         printf "# $i checks performed for region $label [0x%x, 0x%x]\n", $start, $end;
    }
}

# TODO: arguably, we should allow aliasing of the low app shadow region
# with the mid/high app shadow regions (likewise for meta regions), since
# non-PIE vs. PIE are mutually exclusive.
my $overlap = printMappings (\@fineGrainedMappings);
print "\n";
$overlap = $overlap || printMappings (\@allMappings);

printf "kShadowMsk    = 0x%x\n", $kShadowMsk;
printf "kShadowXor    = 0x%x\n", $kShadowXor;
printf "kShadowAdd    = 0x%x\n", $kShadowAdd;

print "kMetaShadowMskOverride = ";
if ($kMetaShadowMskOverride == $kShadowMsk) {
    print "kShadowMsk\n";
} else {
    printf "0x%x\n", $kMetaShadowMskOverride;
}

if ($overlap) {
    print "\n";
    print "ERROR: mappings contain overlapping regions\n";
}

my $shadowMetaMin1 = $shadowMin;
my $shadowMetaMax1 = $shadowMax;
my $shadowMetaMin2 = $metaMin;
my $shadowMetaMax2 = $metaMax;
my $reversedMetaShadows = ($shadowMax > $metaMin);
if ($reversedMetaShadows) {
    $shadowMetaMin1 = $metaMin;
    $shadowMetaMax1 = $metaMax;
    $shadowMetaMin2 = $shadowMin;
    $shadowMetaMax2 = $shadowMax;
}

print "\n";
print "Testing ordering of memory regions ...\n";
# compiler-rt/lib/tsan/rtl/tsan_platform_posix.cpp::CheckAndProtect assumes a
# fixed order for memory regions.
tryProtectRange ($kLoAppMemBeg, $shadowMetaMin1, "LoAppMemBeg", "ShadowMetaMin1");
tryProtectRange ($shadowMetaMax1, $shadowMetaMin2, "ShadowMetaMax1", "ShadowMetaMin2");
if ($kMidAppMemBeg != 0) {
    tryProtectRange ($shadowMetaMax2, $kMidAppMemBeg, "ShadowMetaMax2", "MidAppMemBeg");
    tryProtectRange ($kMidAppMemBeg, $kHeapMemBeg, "MidAppMemBeg", "HeapMemBeg");
} else {
    tryProtectRange ($shadowMetaMax2, $kHeapMemBeg, "MetaMax", "HeapMemBeg");
}
tryProtectRange ($kHeapMemEnd, $kHiAppMemBeg, "HeapMemEnd", "HiAppMemBeg");

if (($kShadowAdd != 0) && ($kShadowXor != 0)) {
    print "\n";
    print "WARNING: both kShadowAdd and kShadowXor are non-zero. This is inefficient.\n";
}

if ($reversedMetaShadows) {
    print "\n";
    print "WARNING: order of shadow and meta regions is reversed\n";
}

print "\n";
print "# Configuration: $configuration\n";

if ($ignoreErrors) {
    print "\n";
    print "WARNING: ignore-error mode enabled\n";
    print "\n";
}

print "\n";
print "TODO: HeapEnd() { return HeapMemEnd() + PrimaryAllocator::AdditionalSize(); }\n";
print "i.e., the end of the heap can't be adjacent to another region\n";
