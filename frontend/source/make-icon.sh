#!/bin/bash
##
# Make an icon based on the SVG
#

# Tool to use for conversion (eg 'convert', 'convert.im6')
convert_tool="${convert_tool:-convert}"

# Sizes
size=128
inset=4
outset=0

# Colourmap colour - use #rgb or a named colour, or empty for none
colourmap=
# 3d highlight - use 0, 1, 2 for increasingly soft, or empty for none
highlight=
# Whether we generate a bubble effect or not (use true or false)
bubble=false
bubbleweight=8
# Whether we trim the edges before we process the image
trim=false
# Any surrounding glow, and strength of the glow (larger is wider glow)
glow=
glowweight=5


##
# Output a help message and exit.
function help() {
    cat <<EOM
Create an icon from an SVG.
Syntax: $0 [<options>] <svg-file> [<png-file>] [<size> [<inset>]]

Options:
    --bubble                Use a 'bubble' gel style
    --bubble-weight <size>  How strong the bubble effect is (default $bubbleweight, increase for more bubble)
    --trim                  Trim down the image so that it isn't internally bordered
    --colour <colour>       Change the colour of the icon
    --highlight <level>     Put a 3d highlight on the icon, with level 0, 1, 2.
    --size <size>           Size of the icon to generate (default $size)
    --inset <size>          Size of inset to add (default $inset)
    --outset <size>         Size of outset to add (default $outset)
    --glow <colour>         Add a glow around the image
    --glow-weight <size>    How strong the glow effect is (default $glowweight, increase for more spread)
EOM
    exit 0
}

# Process the parameters
while [[ "${1:0:1}" == '-' ]] ; do
    if [[ "$1" == '--bubble' ]] ; then
        bubble=true
        shift

    elif [[ "$1" == '--bubble-weight' ]] ; then
        bubbleweight=$2
        shift
        shift

    elif [[ "$1" == '--trim' ]] ; then
        trim=true
        shift

    elif [[ "$1" == '--colour' ]] ; then
        colourmap=$2
        shift
        shift

    elif [[ "$1" == '--glow' ]] ; then
        glow=$2
        shift
        shift

    elif [[ "$1" == '--glow-weight' ]] ; then
        glowweight=$2
        shift
        shift

    elif [[ "$1" == '--highlight' ]] ; then
        highlight=$2
        shift
        shift

    elif [[ "$1" == '--inset' ]] ; then
        inset=$2
        shift
        shift

    elif [[ "$1" == '--outset' ]] ; then
        outset=$2
        shift
        shift

    elif [[ "$1" == '--size' ]] ; then
        size=$2
        shift
        shift

    # Help message
    elif [[ "$1" == '-h' ||
            "$1" == '--help' ]] ; then
        help

    # Not recognised
    else
        echo "Unrecognised switch '$1'" >&2
        exit 1
    fi
done

if [[ "${1:-}" == '' ]] ; then
    help
fi

# Only set the icon number if we know it's from the noun project
iconnum=
name="${1//.svg/}"
json="$name.json"

shift

if [[ "${1:-}" =~ \.png$ ]] ; then
    output="$1"
    shift
else
    output="$(basename "${name}").png"
fi

if [[ "${1:-}" =~ ^[0-9]+$ ]] ; then
    size=$1
    shift
fi

if [[ "${1:-}" =~ ^[0-9]+$ ]] ; then
    inset=$1
    shift
fi

if [[ "${1:-}" != '' ]] ; then
    echo "Unreocgnised parameter '$1'" >&2
    exit 1
fi


# Fix up options
if $bubble ; then
    highlight=
fi

# Read configuration from the JSON File
author=
copyright=
title=
description=
if [[ -f "$json" ]] ; then
    # We should extract the attribution information from the local JSON File
    author="$(jq -r .icon.uploader.name "$json")"
    copyright="$(jq -r .icon.license_description "$json"): $(jq -r .icon.attribution "$json")"
    title="$(jq -r .icon.term "$json")"
    iconnum=$(jq -r .icon.id "$json")
    uri="https://thenounproject.com/$(jq -r .icon.permalink "$json")"
fi
if [[ "$title" != "" && "$iconnum" != '' ]] ; then
    description="$title, icon $iconnum by $author"
fi
if [[ "$iconnum" ]] ; then
    uri="https://thenounproject.com/browse/?i=$iconnum"
fi
set_args=()
# For text field names:
#    http://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html#C.Anc-text
if [[ "$author" != '' ]] ; then
    set_args+=(-set Author "$author")
fi
if [[ "$copyright" != '' ]] ; then
    set_args+=(-set Copyright "$copyright")
fi
if [[ "$title" != '' ]] ; then
    set_args+=(-set Title "$title")
fi
if [[ "$description" != '' ]] ; then
    set_args+=(-set Description "$description")
fi

size=$(( size - inset * 2 ))
inset=$(( inset + outset ))


highlight_args=()
if [[ "$highlight" != '' ]] ; then
    highlight_args=( \( +clone -alpha Extract -blur "0x$highlight" -shade 120x45 \) +swap -compose copyopacity -composite )
fi

colourmap_args=()
if [[ "$colourmap" != '' ]] ; then
    colourmap_file=/tmp/colourmap.png
    if [[ "$highlight" != '' ]] ; then
        # If we're using the highlight, then the middle needs to be the colour
        # we're interested in, and the end of the scale needs to be darker.
        "$convert_tool" xc:#000 "xc:$colourmap" "xc:$colourmap" xc:#fff +append -filter Cubic -resize 256x10\! -rotate 90 "$colourmap_file"
    else
        "$convert_tool" -size 10x256 "gradient:$colourmap-#fff" "$colourmap_file"
    fi
    colourmap_args=(-channel RGB "$colourmap_file" "-clut" -channel RGBA)
fi

resize_args=(-resize "${size}x${size}")
trim_args=()
if $trim ; then
    trim_args=(-trim -border 4 "${resize_args[@]}")
    resize_args=(-gravity Center -extent "${size}x${size}")
fi

# Commands to build the image
makeimage_args=(
            -size "$((size))x$((size))"
            -bordercolor none \
            -background none \
            -alpha on \
            -density 1200 \
            "${trim_args[@]}" \
            "${resize_args[@]}" \
            -border "${inset}x${inset}" \
            "$name.svg" \
        )

glow_args=()
if [[ "$glow" != '' ]] ; then
    glow_args=( \( +clone -background "$glow" \
                   -shadow "100x${glowweight}+0+0" \
                   -channel A -level 0,50% +channel \
                \)
                -background none -compose DstOver -flatten \
              )
fi

if ${bubble:-false} ; then
    # Bubble doesn't appear to retain alpha on ImageMagick 7.
    "$convert_tool" \( \
                "${makeimage_args[@]}" +repage \
                "${colourmap_args[@]}" \
            \) \
            \( \
                +clone -bordercolor None -border 1x1 \
                -alpha Extract -blur "0x$bubbleweight" -shade 130x30 -alpha On \
                -background gray50 -alpha background -auto-level \
                -function polynomial  3.5,-5.05,2.05,0.3 \
                \( +clone -alpha extract  -blur 0x2 \) \
                -channel RGB -compose multiply -composite \
                +channel +compose -chop 1x1 \
            \) \
            -compose Hardlight -composite \
            "${glow_args[@]}" \
            "${set_args[@]}" \
            "$output"
else
    "$convert_tool" \( \
                "${makeimage_args[@]}" \
            \) \
            "${highlight_args[@]}" \
            "${colourmap_args[@]}" \
            "${glow_args[@]}" \
            "${set_args[@]}" \
            "$output"
fi
