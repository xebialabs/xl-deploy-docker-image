#!/bin/bash

IP_ADDRESS=$(hostname -i)

echo "APP_ROOT=${APP_ROOT}"
echo "BOOTSTRAP_DIR=${BOOTSTRAP_DIR}"
echo "DATA_DIR=${DATA_DIR}"
echo "DEVELOPMENT_MODE=${DEVELOPMENT_MODE}"

function generate_keystore {
    if [[ ! -d ${BOOTSTRAP_DIR}/conf ]]; then
        mkdir ${BOOTSTRAP_DIR}/conf
    fi

    if [[ ! -e ${BOOTSTRAP_DIR}/conf/repository-keystore.jceks ]]; then
        echo "Generating random keystore"
        keytool -genseckey -alias deployit-passsword-key -keyalg aes -keysize 128 -keypass "deployit" -keystore ${BOOTSTRAP_DIR}/conf/repository-keystore.jceks -storetype jceks -storepass "docker"
        cp /tmp/templates/deployit.conf ${BOOTSTRAP_DIR}/conf
        echo "repository.keystore.password=docker" >> ${BOOTSTRAP_DIR}/conf/deployit.conf
    fi
}

function copy_extensions {
    DIRS=( "plugins" "hotfix" "ext" )
    for i in "${DIRS[@]}"; do
        if [[ -d ${BOOTSTRAP_DIR}/$i ]]; then
            if [ "$i" == "ext" ] && [ "${DEVELOPMENT_MODE}" == "true" ]; then
                echo "Linking $i from installaton to ${BOOTSTRAP_DIR}"
                rm -rf ${APP_HOME}/$i
                ln -s ${BOOTSTRAP_DIR}/$i ${APP_HOME}/$i
            else
                echo "Copying $i to installation..."
                cp -fr ${BOOTSTRAP_DIR}/$i/* ${APP_HOME}/$i
                # N.B.: Does not copy hidden files!
            fi
        fi
    done
}

function copy_bootstrap_conf {
    FILES=( "repository-keystore.jceks" "logback.xml" "security.policy", "xl-deploy.policy" "deployit-defaults.properties" "deployit-security.xml" "keystore.jks" "deployit.conf" "deployit-license.lic" )
    for i in "${FILES[@]}"; do
        if [[ -e ${BOOTSTRAP_DIR}/conf/$i ]]; then
            echo "Copying $i to installation..."
            cp -f ${BOOTSTRAP_DIR}/conf/$i ${APP_HOME}/conf
        fi
    done
}

function configure {
    echo "Customizing configuration based on environment settings"

    sed -e "s/NODE_NAME/${IP_ADDRESS}/g" '/tmp/templates/xl-deploy.conf' > "${APP_HOME}/conf/xl-deploy.conf"
    for e in `env | grep '^'`; do
        IFS='=' read -ra KV <<< "$e"
        sed -e "s#${KV[0]}#${KV[1]}#g" -i "${APP_HOME}/conf/xl-deploy.conf"
    done

    case ${DB_TYPE} in
        h2)
            DB_DRIVER="org.h2.Driver"
            ;;
        oracle)
            DB_DRIVER="oracle.jdbc.OracleDriver"
            echo "Still need support for 'oracle' jdbc driver"
            exit 1
            ;;
        mysql)
            DB_DRIVER="com.mysql.jdbc.Driver"
            curl http://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.39/mysql-connector-java-5.1.39.jar -o ${APP_HOME}/lib/mysql-connector-java-5.1.39.jar
            ;;
        postgres)
            DB_DRIVER="org.postgresql.Driver"
            curl http://repo1.maven.org/maven2/org/postgresql/postgresql/9.4.1211/postgresql-9.4.1211.jar -o ${APP_HOME}/lib/postgresql-9.4.1211.jar
            ;;
        mssql)
            DB_DRIVER="com.microsoft.sqlserver.jdbc.SQLServerDriver"
            curl http://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/6.2.2.jre8/mssql-jdbc-6.2.2.jre8.jar -o ${APP_HOME}/lib/mssql-jdbc-6.2.2.jre8.jar
            ;;
        db2)
            DB_DRIVER="com.ibm.db2.jcc.DB2Driver"
            echo "Still need support for 'db2' jdbc driver"
            exit 1
            ;;
        *)
            echo "Unknown DB type '${DB_TYPE}', supported db types are 'h2', 'oracle', 'mysql', 'postgres', 'mssql', 'db2'"
            exit 1
            ;;
    esac
    sed -e "s/DB_DRIVER/${DB_DRIVER}/g" -i "${APP_HOME}/conf/xl-deploy.conf"
    if [[ ! -e ${APP_HOME}/conf/deployit.conf ]]; then
        cp /tmp/templates/deployit.conf ${APP_HOME}/conf
        cp /tmp/templates/xld-wrapper-linux.conf ${APP_HOME}/conf
        cp /tmp/templates/logback.xml ${APP_HOME}/conf
    fi
}

copy_extensions
copy_bootstrap_conf
configure
generate_keystore

exec ${APP_HOME}/bin/run.sh "$@"
