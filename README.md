# docker-hadoop3

Single node Hadoop setup having version 3.2.2 along with below applications:

| App| Version |
| --- | --- |
| Hive | 3.1.2 |
| Spark | 3.1.1 |
| Hudi | 0.8.0 |
| Hue | 4.9.0 |

MySQL has been configured as Hive metastore as well as engine for Hue.

Steps to run:
- Build the image: `docker build -t hadoop ./`

- Run container: `docker run -p 8088:8088 -p -p 8042:8042 -p 8888:8888 -p 10002:10002 -p 9870:9870 --name hadoop -d hadoop`
  
Access WebUI for:
- YARN: http://localhost:8088
- Namenode: http://localhost:9870 
- HiveServer2: http://localhost:10002
- Hue: http://localhost:8888