#!/bin/bash
# Checagem de sanidade: testa se arquivo PAS para compilação foi fornecido e é válido.
if [ -z "$1" ]; then
    echo "erro: nome de arquivo faltando. Lembre-se de colocar \"%d/%f\" como parâmetro para este script no Geany." >&2
    exit 1
fi
if [ ! -f "$1" ]; then
    echo "erro: arquivo \"$1\" não encontrado. Especifique o caminho exato com \"%d/%f\"." >&2
    exit 1
fi

# Checagem de sanidade: testa se nome do arquivo é válido.
ARQUIVO=$(basename "$1")
if [ -z "$ARQUIVO" ]; then
    echo "erro: nome de arquivo não reconhecido. Lembre-se de colocar \"%d/%f\" como parâmetro para este script no Geany." >&2
    exit 1
fi

# Checagem de sanidade: testa se diretório do projeto é válido.
PROJETO=$(dirname "$1")
if [ -z "$PROJETO" ]; then
    echo "erro: nome do diretório do projeto não reconhecido. Lembre-se de colocar \"%d/%f\" como parâmetro para este script no Geany." >&2
    exit 1
fi
if [ ! -d "$PROJETO" ]; then
    echo "erro: diretório \"$PROJETO\" não encontrado. Especifique o caminho exato com \"%d/%f\"." >&2
    exit 1
fi

# Checagem de sanidade: testa se arquivo de saída tem nome diferente do arquivo de entrada.
EXECUTAVEL=$(echo $ARQUIVO | sed 's/pas/com/')
if [ "$EXECUTAVEL" = "$ARQUIVO" ]; then
    echo "erro: executável \"$EXECUTAVEL\" não pode ter o mesmo nome de arquivo de entrada." >&2
    exit 1
fi

# Checagem de sanidade: teste se diretório do repositório é válido.
UNIX2DOS=$(whereis unix2dos)
if [ -z "$UNIX2DOS" ]; then
    echo "erro: programa unix2dos não encontrado. Instale-o para usar este script." >&2
    exit 1
fi

# Checagem de sanidade: teste se diretório do repositório é válido.
DIRETORIO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
if [ -z "$DIRETORIO" ]; then
    echo "erro: diretório do repositório não reconhecido." >&2
    exit 1
fi
if [ ! -d "$DIRETORIO" ]; then
    echo "erro: diretório \"$DIRETORIO\" não encontrado." >&2
    exit 1
fi

DISCO="$DIRETORIO/develop.dsk"
OPENMSX=/opt/openMSX/bin/openmsx #$(which openmsx)
SANDBOX="$DIRETORIO/src/sandbox/"
TEMPORARIO=$(mktemp)

#
# A cada vez que é executado, o script apaga todo o conteúdo da sandbox,
# recria o diretório e copia tudo para lá.
#
rm -rf "$SANDBOX"
mkdir "$SANDBOX"

#
# Converte todos os arquivos .pas em formato MSX-DOS ao copiar para sandbox
#
for file in "$PROJETO"/*.pas; do
    echo "file: $file"
    unix2dos < "$file" > "$SANDBOX/$file"
    touch "$file"
done

#
# Aqui ele altera o script TCL, para ser executado no boot do OpenMSX.
#
cat << EOF > "$TEMPORARIO"
set power off
ext ide

hda $DISCO
diskmanipulator format hda4
diskmanipulator import hda4 $SANDBOX

set power on
after boot "set speed 10000"

after time 16 "type \"turbo\\rn\\ro\\rc\\rq\\rcd:$ARQUIVO\\r\""
after time 36 "type \"q\\rd:\\r$EXECUTAVEL\\r\""
#after time 50 "set speed 100"
#after time 70 "diskmanipulator export hda4 \"$SANDBOX\""
EOF

#
# Executa o emulador pra compilar o programa. A configuração é um MSX 2
# caprichado, e o script que faz o milagre é um script em TCL, definido
# no alto desse arquivo de configuração.
$OPENMSX -machine Boosted_MSX2_EN -script "$TEMPORARIO"
rm "$TEMPORARIO"

#
# Quando o OpenMSX é encerrado, o script retoma o controle, e faz o 
# a cópia dos arquivos atualizados de volta para a pasta $PROJETO
#
rsync "$SANDBOX/" "$PROJETO/"
