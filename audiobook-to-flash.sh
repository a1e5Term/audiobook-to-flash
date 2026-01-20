#!/bin/bash
#папку new не удаляет
#======================================================================

#Флешка должна быть слева
#Аудиокнига справа

<< 'MULTILINE-COMMENT'

DOUBLECMD#TOOLBAR#XMLDATA<?xml version="1.0" encoding="UTF-8"?>
<doublecmd>
  <Program>
    <Hint>audiobook-to-flash.sh LEFT_PANEL RIGHT_PANEL</Hint>
    <Command>audiobook-to-flash.sh %pl %pr</Command>
    <Params>%t1</Params>
  </Program>
</doublecmd>

MULTILINE-COMMENT

#======================================================================

set -eo pipefail
#e остановка скрипта если в строке ошибка
#o pipefail остановка при обнаружении неизвестных команд

usage() {
	echo "Usage: ./"$(basename $0) '"PATH_FLASH" "PATH_AUDIOBOOK"'
	exit 0
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
	usage
	exit 0
fi

check_arguments() {
    # Проверяем, передан ли первый аргумент
    if [ -z "$1" ]; then
        echo "Пожалуйста, укажите путь к флешке."
        usage
        #Код возврата 0 обычно означает успешное завершение программы.
        exit 1
    fi

    # Проверяем, существует ли путь к флешке
    if [ ! -d "$1" ]; then
        echo "Путь '$1' не найден или не является папкой."
        exit 1
    else
		PATH_FLASH="$1"
    fi

    # Проверяем, передан ли второй аргумент
    if [ -z "$2" ]; then
        echo "Укажите имя папки с аудио."
        usage
        exit 1
    fi

    # Проверяем, существует ли папка с аудио
    if [ ! -d "$2" ]; then
        echo "Папка '$2' не найдена."
        exit 1
    else
		PATH_AUDIOBOOK="$2"
    fi

    echo -e "Путь к флешке: \n\t$1"
    echo -e "Папка с аудио: \n\t$2"
}

clear_flash () {
	clear
	echo "ОЧИСТКА ФЛЕШКИ"
	if [ -d "$PATH_FLASH" ]; then
		cd "$PATH_FLASH"
		rm -rf * > /dev/null
		#rm -rf .* > /dev/null
		#ОЧИСТКА ФЛЕШКИ
#rm: refusing to remove '.' or '..' directory: skipping '.'
#rm: refusing to remove '.' or '..' directory: skipping '..'
		if [ $? -eq 1 ]; then
			echo "rm -rf * - ошибка"

			rm -rf * && status="удалено" || status="не удалено"
			echo "Статус выполнения: $status"

			if [ -z "$(ls -A)" ]; then
				echo "Команда выполнена, файлы удалены."
			else
				echo "Команда не выполнена, файлы остались."
			fi
			
			exit
		fi

		NAME="$(date +"%Y-%m-%d_%H-%M-%S")"
		mkdir $NAME
		echo "флешка подготовлена"
	else
		echo "что то не так. -d "$PATH_FLASH" не находит"
	fi
	sleep 3
}

copy_dir () {
	# Удаляем символы
	CLEAR_FOLDER_NAME=$(echo "$folder_name" | sed 's/ /_/g' | sed 's/[^a-zA-Zа-яА-Я0-9._-]//g')
		#s/ /_/g — эта часть заменяет все пробелы на нижние подчеркивания.
		#s/[^a-zA-Zа-яА-Я0-9._-]//g — эта часть удаляет все символы, которые не входят в указанный набор.

	NEW_FOLDER_NAME="NEW_${CLEAR_FOLDER_NAME}"

	# Получаем путь к родительской директории
	PARENT_DIR=$(dirname "$PATH_AUDIOBOOK")
	# echo "$PARENT_DIR"

	# если осталась папка пустая от предыдущего неудачного копирования на флеху. удаяем её
	[[ -d "${PARENT_DIR}/${NEW_FOLDER_NAME}" ]] && rm -rf -r "${PARENT_DIR}/${NEW_FOLDER_NAME}"
	clear
	echo -e "КОПИРОВАНИЕ\n"
	echo "$PATH_AUDIOBOOK" "$PARENT_DIR/$NEW_FOLDER_NAME"
	cp -rv "$PATH_AUDIOBOOK" "$PARENT_DIR/$NEW_FOLDER_NAME"

	# Проверяем, скопировалась ли папка
	if [ ! -d "$PARENT_DIR/$new_name" ]; then
		echo "Папка не скопировалась. " "$PARENT_DIR/$new_name"
		exit 1
	else
		echo "Папка скопировалась. " "$PARENT_DIR/$new_name"
	fi
	
	#переименовать оригинальную папку
	mv "$PATH_AUDIOBOOK" "$PARENT_DIR/_${folder_name}"
	
	sleep 3
}

check_mat2 (){
	# mat2
	if command -v mat2 >/dev/null 2>&1 ; then
		MAT_COMMAND='mat2'
	elif command -v mat >/dev/null 2>&1 ; then
		MAT_COMMAND='mat'
	else	
		sudo apt install mat2 -y
	fi
}

func_mat2 () {
	clear
	echo -e "Очистка от метаданных. mat2\n"
	# нужно зациклить поиск вложенных папок до тех по пока их не будет
	# вытаскиваем из подпапки если она есть
	SUB_DIR=$(find "$PARENT_DIR/$new_name" -mindepth 1 -maxdepth 1 -type d)

	# Проверяем, найдена ли подпапка
	if [ -d "$SUB_DIR" ]; then
		# Перемещаем файлы из папка2 в папка1
		mv "$SUB_DIR"/* "$PARENT_DIR/${NEW_FOLDER_NAME}"
		rmdir "$SUB_DIR"
	fi

	cd "$PARENT_DIR/${NEW_FOLDER_NAME}"

	# -----------------------------------------------------------------------------------
	# удалить все не mp3
	find . -type f ! -name "*.mp3" -exec rm {} +
	# -----------------------------------------------------------------------------------

	check_mat2

	#read a

	$MAT_COMMAND "$PARENT_DIR/${NEW_FOLDER_NAME}" && echo "ok $MAT_COMMAND"
	#read a



	if [ $MAT_COMMAND == mat2 ]; then
		# после mat2 удлаить не содержащее "clean"
		find . -type f ! -name '*clean*' -exec rm {} +
	fi

}


rename_mat (){
	# это не зайдет в подпапку
	a=1; for f in *; do [ -f "$f" ] && mv "$f" "$(printf "%03d" $a).${f##*.}"; a=$((a + 1)); done
}

del_dir (){
	if [ -d "$PARENT_DIR/${NEW_FOLDER_NAME}" ]; then
		rm -rf -r "$PARENT_DIR/${NEW_FOLDER_NAME}/"

		#read a
		# Проверяем, удалилась ли папка
		if [ ! -d "$PARENT_DIR/${NEW_FOLDER_NAME}" ]; then
			echo "Папка удалена. " "$PARENT_DIR/${NEW_FOLDER_NAME}"
		else
			echo "Папка НЕ удалена. " "$PARENT_DIR/${NEW_FOLDER_NAME}"
		fi
		#read a
	fi
	
}

# копирование на флешку
copy_to_flash () {
	clear
	echo "КОПИРОВАНИЕ НА ФЛЕШКУ"
	echo "$PARENT_DIR/${NEW_FOLDER_NAME}/*" "$PATH_FLASH/${NAME}"

	cp -v "$PARENT_DIR/$NEW_FOLDER_NAME/"* "$PATH_FLASH/${NAME}/"
	
	#if [ -d "$PARENT_DIR/${NEW_FOLDER_NAME}/" ]; then
		#rsync -v "$PARENT_DIR/${NEW_FOLDER_NAME}/" "$PATH_FLASH/${NAME}/" > /dev/null
	#else
		#echo не найдена папка "$PARENT_DIR/${NEW_FOLDER_NAME}/"
	#fi
	
	echo
	echo "ГОТОВО"
}

umnt (){
	sleep 3
	clear
	echo umount "$PATH_FLASH"
	umount "$PATH_FLASH"
}

full () {
	clear_flash
	copy_dir
	func_mat2
	rename_mat
	copy_to_flash
	del_dir
	umnt "$1"
}

commands=("Full"  \
		  "clear_flash"  \
		  "copy_dir"  \
		  "func_mat2"  \
		  "rename_mat"  \
		  "copy_to_flash")

selectfzf () {
	CMD=$(printf "%s\n" "${commands[@]}" | fzf --reverse --no-info --cycle)

	case $CMD in
		"clear_flash")
			clear_flash
			selectfzf
			;;
			
		"copy_dir")
			copy_dir "$2"
			read
			selectfzf
			;;
			
		"func_mat2")
			func_mat2
			selectfzf
			;;
			
		"rename_mat")
			rename_mat
			selectfzf
			;;
			
		"copy_to_flash")
			copy_to_flash
			selectfzf
			;;
						
		"Full")
			full
			exit 0
			;;
			
		*)
			echo "Неизвестная команда"
			;;
	esac

}

main () {
	. /etc/os-release

	check_arguments "$1" "$2"

	# Извлекаем имя папки из полного пути
	folder_name=$(basename "$PATH_AUDIOBOOK")
	read

	if [[ "$3" == "-f" || "$3" == "--full" ]]; then
		full "$1"
		exit 0
	fi

	selectfzf "$1" "$2"
}

main "$@"
