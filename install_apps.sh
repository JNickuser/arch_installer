#!/bin/bash

name=$(cat /tmp/user_name)

# Getting app list
apps_path="/tmp/apps.csv"
curl https://raw.githubusercontent.com/JNickuser/arch_installer/master/apps.csv > $apps_path

# Listing apps and letting user select them
dialog --title "Welcome!" \
    --msgbox "Welcome to the installation script for your apps and dotfiles!" \
    10 60

apps=("essential" "Essentials" on
    "network" "Network" on
    "bluetooth" "Bluetooth support utilities" on
    "tools" "Useful tools to have" on
    "FsSupport" "Different file system support" on
    "fonts" "Nice fonts to have" on
    "tmux" "Tmux" on
    "notifier" "Notification tools" on
    "git" "Git and git tools" on
    "i3" "i3 wm" on
    "zsh" "The Z-Shell (zsh)" on
    "neovim" "Neovim" on
    "urxvt" "Urxvt" on
    "firefox" "Firefox (browser)" on
    "office" "LibreOffice suite" on
    "design" "Design programs" off
    "multimedia" "Useful multimedia utilities" on
    "social" "Social desktop apps" off
    "anki" "Anki flashcard program" off)

dialog --checklist \
    "You can now choose what group of apps you want to install. \n\n\
    You can select an option with SPACE and valid your choices with ENTER." \
    0 0 0 \
    "${apps[@]}" 2> app_choices

choices=$(cat app_choices) && rm app_choices

# Parsing the CSV
selection="^$(echo "$choices" | sed -e 's/ /,|^/g'),"
lines=$(grep -E "$selection" "$apps_path")
count=$(echo "$lines" | wc -l)
packages=$(echo "$lines" | awk -F, {'print $2'})

echo "$selection" "$lines" "$count" >> "/tmp/packages"

# Updating the System
pacman -Syu --noconfirm

# Installing user's selected packages
rm -f /tmp/aur_queue

dialog --title "Let's go!" --msgbox \
    "The system will now install everything you need.\n\n\
    It will take some time.\n\n " \
    60

c=0
while read -r line; do
    c=$(( "$c" + 1 ))

    dialog --title "Arch Linux Installation" --infobox \
        "Downloading and installing program $c out of $count: $line..." \
        8 70

    ((pacman --noconfirm --needed -S "$line" > /tmp/arch_install 2>&1) \
        || echo "$line" >> /tmp/aur_queue) \
        || echo "$line" >> /tmp/arch_install_failed

    if [ "$line" = "zsh" ]; then
        # Set Zsh as default terminal for our user
        chsh -s "$(which zsh)" "$name"
    fi

    if [ "$line" = "networkmanager" ]; then
        # Enable the service NetworkManager for systemd
        systemctl enable NetworkManager.service
    fi
done <<< "$packages"

# Adding permission to sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Getting the next script to run
curl https://raw.githubusercontent.com/JNickuser/arch_installer/master/install_user.sh \
    -o /tmp/install_user.sh

#Switch user and run the final script
sudo -u "$name" bash /tmp/install_user.sh
