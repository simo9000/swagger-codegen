set executable=.\modules\swagger-codegen-cli\target\swagger-codegen-cli.jar

If Not Exist %executable% (
  mvn clean package
)

REM set JAVA_OPTS=%JAVA_OPTS% -Xmx1024M
set ags=generate -i http://us6955sqld/REST/ -l csharpConsola -o "..\RAD DAQ REST API\gentargets\RAD_API\C# Client\generated"

java %JAVA_OPTS% -jar %executable% %ags%
