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

# Checagem de sanidade: testa se arquivo de erro tem nome diferente do arquivo de entrada.
ERRO=$(echo $ARQUIVO | sed 's/pas/err/')
if [ "$ERRO" = "$ARQUIVO" ]; then
    echo "erro: arquivo de erro \"$ERRO\" não pode ter o mesmo nome de arquivo de entrada." >&2
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
OPENMSX=$(which openmsx)
SANDBOX="$DIRETORIO/src/sandbox/"
TEMPORARIO=$(mktemp)

#
# A cada vez que é executado, o script apaga todo o conteúdo da sandbox,
# recria o diretório e copia tudo para lá.
#
rm -rf "$SANDBOX"
mkdir "$SANDBOX"

#
# Remove lixo da pasta que contém o programa a ser compilado.
#
find $PWD -name "*~" -or -name "*.err" -or -name "*.bak" -delete

#
# Converte todos os arquivos .pas em formato MSX-DOS ao copiar para sandbox
#
for file in $PROJETO/*.pas; do
    echo "file: $file"
    unix2dos < "$file" > "$SANDBOX/$file"
    touch "$file"
done

TCL_SCRIPT="$DIRETORIO/templates/tp33.tcl"
DRIVE="$DIRETORIO/develop.dsk"

#
# Modifica o script TCL com os parâmetros obtidos.
#
cat "$TCL_SCRIPT" | sed "s|%%DRIVE%%|$DISCO|g" | sed "s|%%SANDBOX%%|$SANDBOX|g" > "$TEMPORARIO"

#
# Aqui ele cria um COMPILA.BAT, para ser executado no boot do OpenMSX.
# Depois de compilado e executado, o arquivo gerado é exportado para a
# pasta do SANDBOX.
#
COMPILABAT="$SANDBOX/compila.bat"
cat << EOF > "$COMPILABAT"
D:
C:\\TP3\\TP33F $ARQUIVO /r$ERRO
C:\\MEMMAN _SYSTEM@D:\\$EXECUTAVEL@
c:\\OMSXCTL diskmanipulator export hda $SANDBOX
c:\\OMSXCTL set speed 100
EOF
unix2dos "$COMPILABAT"

#
# Executa o emulador pra compilar o programa. A configuração é um MSX 2
# caprichado, e o script que faz o milagre é um script em TCL, definido
# no alto desse arquivo de configuração.
#
OPENMSX=$(which openmsx)
$OPENMSX -machine Boosted_MSX2_EN -script omsxctl.tcl -script "$TEMPORARIO"
#$OPENMSX -machine Boosted_MSX2+_JP -script "$TEMPORARIO"
#$OPENMSX -machine Boosted_MSXturboR_with_IDE -script "$TEMPORARIO"
rm "$TEMPORARIO"

#
# Quando o OpenMSX é encerrado, o script retoma o controle, e faz o
# a cópia dos arquivos atualizados de volta para a pasta $PROJETO
#
rsync "$SANDBOX/" "$PROJETO/"
