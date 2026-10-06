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
echo "ARQUIVO: $ARQUIVO"
if [ -z "$ARQUIVO" ]; then
    echo "erro: nome de arquivo não reconhecido. Lembre-se de colocar \"%d/%f\" como parâmetro para este script no Geany." >&2
    exit 1
fi

# Checagem de sanidade: testa se diretório do projeto é válido.
PROJETO=$(dirname "$1")
echo "PROJETO: $PROJETO"
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
echo "EXECUTAVEL: $EXECUTAVEL"
if [ "$EXECUTAVEL" = "$ARQUIVO" ]; then
    echo "erro: executável \"$EXECUTAVEL\" não pode ter o mesmo nome de arquivo de entrada." >&2
    exit 1
fi

# Checagem de sanidade: testa se a ferramenta unix2dos existe.
UNIX2DOS=$(which unix2dos)
if [ -z "$UNIX2DOS" ]; then
    echo "erro: programa unix2dos não encontrado. Instale-o para usar este script." >&2
    exit 1
fi

# Checagem de sanidade: testa se a ferramenta expand existe.
EXPAND=$(which expand)
if [ -z "$EXPAND" ]; then
    echo "aviso: programa expand não encontrado. Conversão de tabs em espaços não será feita." >&2
fi

# Checagem de sanidade: teste se diretório do repositório é válido.
DIRETORIO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
echo "DIRETORIO: $DIRETORIO"
if [ -z "$DIRETORIO" ]; then
    echo "erro: diretório do repositório não reconhecido." >&2
    exit 1
fi
if [ ! -d "$DIRETORIO" ]; then
    echo "erro: diretório \"$DIRETORIO\" não encontrado." >&2
    exit 1
fi

DISCO="$DIRETORIO/develop.dsk"
echo "DISCO: $DISCO"
OPENMSX=/opt/openMSX/bin/openmsx #$(which openmsx)
echo "OPENMSX: $OPENMSX"
SANDBOX="$DIRETORIO/src/sandbox/"
echo "SANDBOX: $SANDBOX"
TCL_SCRIPT="$DIRETORIO/templates/tp.tcl"
echo "TCL_SCRIPT: $TCL_SCRIPT"

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
    echo "Arquivo: $file"
    "$UNIX2DOS" < "$file" > "$SANDBOX/"$(basename "$file")
    if [ -f "$EXPAND" ]; then
        $EXPAND --tabs=4 < "$file" > "$SANDBOX/"$(basename "$file")
    fi
done

#
# Modifica o script TCL com os parâmetros obtidos.
#
TMP_SCRIPT=$(mktemp --suffix=.tcl)
echo "TMP_SCRIPT: $TMP_SCRIPT"
cat "$TCL_SCRIPT" | sed "s|%%DRIVE%%|$DISCO|g" | sed "s|%%SANDBOX%%|$SANDBOX|g" | sed "s|%%PAS%%|$ARQUIVO|g" | sed "s|%%COM%%|$EXECUTAVEL|g" > "$TMP_SCRIPT"

#
# Executa o emulador pra compilar o programa. A configuração é um MSX 2
# caprichado, e o script que faz o milagre é um script em TCL, definido
# no alto desse arquivo de configuração.
$OPENMSX -machine Boosted_MSX2_EN -script "$TMP_SCRIPT"
#$OPENMSX -machine Boosted_MSX2+_JP -script "$TMP_SCRIPT"
#$OPENMSX -machine Boosted_MSXturboR_with_IDE -script "$TMP_SCRIPT"
rm "$TMP_SCRIPT"

#
# Quando o OpenMSX é encerrado, o script retoma o controle, e faz o 
# a cópia dos arquivos atualizados de volta para a pasta $PROJETO
#
rsync -c "$SANDBOX/" "$PROJETO/"
