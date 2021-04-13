# docker-hadoop3

Single node Hadoop setup having version 3.2.2 along with below applications:

| Application| Version |
| --- | --- |
| Hive | 3.1.2 |
| Spark | 3.1.1 |
| Hudi | 0.8.0 |
| Hue | 4.9.0 |

Steps to build image:
- Build the image: `docker build -t hadoop ./`

- Run container: `docker run -p 8088:8088 -p -p 8042:8042 -p 8888:8888 -p 10002:10002 \
--name hadoop -d hadoop`
  
Access WebUI for:
- YARN: http://localhost:8088
- HiveServer: http://localhost:10002
- Hue: http://localhost:8888





