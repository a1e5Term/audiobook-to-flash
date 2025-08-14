#!/bin/bash

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

first () {
	SCRIPT_PATH=$(realpath "$0")
	pathMount='/media/user'
	userUUID=$(lsblk -no UUID $(df -P $SCRIPT_PATH | tail -1 | awk '{print $1}'))

	var=$(find $pathMount -mindepth 1 -maxdepth 1 -type d -exec find {} -maxdepth 1 -type f -name "rootuser" \;)
	if [ -f $var ]; then
		var2=$(dirname "$var")
		last_folder=$(basename "$var2")
		rootDiskUUID=$last_folder
	fi

	PATH_FLASH=$(lsblk -o UUID,PATH_FLASH | grep "$UUID_DEVICE" | awk '{print $2}')
}

# Функция для генерации случайного алфавита
alphabetical_random() {
	local ALPHABET="abcdefghijklmnopqrstuvwxyz"
	local INDEX=$((RANDOM % 26))  				# Вычисляем индекс
	local RANDOM_LETTER="${ALPHABET:$INDEX:1}"  # Извлекаем букву по индексу
	echo "$RANDOM_LETTER"  						# Выводим случайную букву
}

clear_flash () {
	echo "очистка флешки"
	if [ -d "$PATH_FLASH" ]; then
	# 	echo "папка сущ."
		cd "$PATH_FLASH"
	# 	pwd
		rm -rf *
	# 	mkdir 2352352
		if [ $? -eq 1 ]; then
			#3 способа
			echo "rm -rf * - ошибка"

			rm -rf * && status="удалено" || status="не удалено"
			echo "Статус выполнения: $status"

			if [ -z "$(ls -A)" ]; then
				echo "Команда выполнена, файлы удалены."
			else
				echo "Команда не выполнена, файлы остались."
			fi
			
			#read a
			
			exit
		fi

		# Запускаем функцию для генерации случайного имени папки
		RANDOM_NAME=$(alphabetical_random)
		RANDOM_NAME2=$(alphabetical_random)

		# Создаём папку с полученным случайным именем из двух букв
	# 	mkdir "${RANDOM_NAME}${RANDOM_NAME2}"
		NAME="$(alphabetical_random)$(alphabetical_random)"
		mkdir $NAME
	# 	echo $(alphabetical_random)$(alphabetical_random)
		echo "флешка подготовлена"
		sleep 5
	else
		echo "что то не так. -d "$PATH_FLASH" не находит"
	fi

}



# ----------------------------------------------------------------------------------------------------------

copy_dir () {
	# Удаляем символы
	#CLEAR_FOLDER_NAME=$(echo "$folder_name" | tr -d '№(–)-' | tr -d ' ' )
	#CLEAR_FOLDER_NAME=$(echo "$folder_name" | tr -d '№()-' | tr -d ' ' )
	CLEAR_FOLDER_NAME=$(echo "$folder_name" | sed 's/ /_/g' | sed 's/[^a-zA-Zа-яА-Я0-9._-]//g')
		#s/ /_/g — эта часть заменяет все пробелы на нижние подчеркивания.
		#s/[^a-zA-Zа-яА-Я0-9._-]//g — эта часть удаляет все символы, которые не входят в указанный набор.

	NEW_FOLDER_NAME="NEW_${CLEAR_FOLDER_NAME}"

	# Получаем путь к родительской директории
	PARENT_DIR=$(dirname "$PATH_AUDIOBOOK")
	# echo "$PARENT_DIR"

	# если осталась папка пустая от предыдущего неудачного копирования на флеху. удаяем её
	[[ -d "${PARENT_DIR}/${NEW_FOLDER_NAME}" ]] && rm -rf "${PARENT_DIR}/${NEW_FOLDER_NAME}"
	clear
	echo "копирование"
	echo "$PATH_AUDIOBOOK" "$PARENT_DIR/$NEW_FOLDER_NAME"
	cp -rv "$PATH_AUDIOBOOK" "$PARENT_DIR/$NEW_FOLDER_NAME"

	# Проверяем, скопировалась ли папка
	if [ ! -d "$PARENT_DIR/$new_name" ]; then
		echo "Папка не скопировалась. " "$PARENT_DIR/$new_name"
		exit 1
	else
		echo "Папка скопировалась. " "$PARENT_DIR/$new_name"
	fi
}

fnc (){
	# если новое имя отличается от старого то копируем с новым именем папку, 
	if [ "$folder_name" != "$NEW_FOLDER_NAME" ]; then
	#     echo 'отличается'
		new_name="$NEW_FOLDER_NAME"

		# если осталась папка пустая от предыдущего неудачного копирования на флеху. удаяем её
		[[ -d "$PARENT_DIR/$new_name" ]] && rm -rf "$PARENT_DIR/$new_name"
		clear
		echo
		echo "$PATH_AUDIOBOOK" "$PARENT_DIR/$new_name"

	else
		new_name="new_${CLEAR_FOLDER_NAME}"

		# если осталась папка пустая от предыдущего неудачного копирования на флеху. удаяем её
		[[ -d "$PARENT_DIR/$new_name" ]] && rm -rf "$PARENT_DIR/$new_name"

		echo "копирование"

	fi

	##переименовать оригинальную папку
	#mv "$PATH_AUDIOBOOK" "$PARENT_DIR/_${folder_name}"


}

func_mat2 () {
	# -----------------------------------------------------------------------------------
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

	# mat2

	if command -v mat2 >/dev/null 2>&1 ; then
		echo
	else	
		sudo apt install mat2 -y
	fi

	mat2 "$PARENT_DIR/${NEW_FOLDER_NAME}" && echo "ok mat2"

	# удлаить после mat2
	find . -type f ! -name '*clean*' -exec rm {} +
}


rename_mat (){

	# это не зайдет во подпапку
	a=1; for f in *; do [ -f "$f" ] && mv "$f" "$(printf "%03d" $a).${f##*.}"; a=$((a + 1)); done

	# это должно работать рекурсивно
	# Начинаем с 1
	# a=1

	# Используем find для поиска всех файлов в текущем каталоге и подкаталогах
	# find . -type f | while read -r f; do
	#     # Получаем директорию файла
	#     dir=$(dirname "$f")
	#     # Переименовываем файл
	#     mv "$f" "$dir/$(printf "%03d" $a).${f##*.}"
	#     # Увеличиваем счетчик
	#     a=$((a + 1))
	# done


	# добавить скрипт удаления
}

copy_to_flash () {
	# "копирование на флешку"
	echo " "
	echo "копирование на флешку"
	echo "$PARENT_DIR/${NEW_FOLDER_NAME}/*" "$PATH_FLASH/"

	# + && echo "cp ok"       не рб
	ls "$PARENT_DIR/${NEW_FOLDER_NAME}/" | sort | xargs -I {} cp -v $PARENT_DIR/${NEW_FOLDER_NAME}/{} "$PATH_FLASH/" && echo "cp ok"
	#read 
	
	rm -rf "$PARENT_DIR/${NEW_FOLDER_NAME}/"
	
	# Проверяем, удалилась ли папка
	if [ ! -d "$PARENT_DIR/${NEW_FOLDER_NAME}" ]; then
		echo "Папка удалена. " "$PARENT_DIR/${NEW_FOLDER_NAME}"
#         exit 1
	fi

	echo
	echo "готово"

}

full () {
	clear_flash
	copy_dir
	func_mat2
	rename_mat
	copy_to_flash
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

	# Вызов функции с аргументами
	check_arguments "$1" "$2"

	# Извлекаем имя папки из полного пути
	folder_name=$(basename "$PATH_AUDIOBOOK")
	read
	echo
	selectfzf "$1" "$2"
}

main "$@"
