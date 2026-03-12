A simple way to set up [Travis CI](https://travis-ci.org/) and Apache Maven to properly deploy snapshots into a maven repository.

The first step is to write a proper pom.xml that allows for the deployment of snapshots, without signing it.

The code bellow shows part of maven build files that is set up to deploy on the sonatype oss repository. By default, the deploy command will deploy the snapshot. If the release profile is active then the project artifacts will be signed and deploy to the release repository. You can find more information [here](http://central.sonatype.org/pages/apache-maven.html).

```xml
 <distributionManagement>
    <snapshotRepository>
      <id>ossrh</id>
      <url>https://oss.sonatype.org/content/repositories/snapshots</url>
    </snapshotRepository>
  </distributionManagement>
  <build>
      <plugin>
        <groupId>org.sonatype.plugins</groupId>
        <artifactId>nexus-staging-maven-plugin</artifactId>
        <version>1.6.3</version>
        <extensions>true</extensions>
        <configuration>
          <serverId>ossrh</serverId>
          <nexusUrl>https://oss.sonatype.org/</nexusUrl>
          <autoReleaseAfterClose>true</autoReleaseAfterClose>
        </configuration>
      </plugin>
    </plugins>
  </build>
  <profiles>
    <profile>
      <id>release</id>
      <build>
        <plugins>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-source-plugin</artifactId>
            <version>2.2.1</version>
            <executions>
              <execution>
                <id>attach-sources</id>
                <goals>
                  <goal>jar-no-fork</goal>
                </goals>
              </execution>
            </executions>
          </plugin>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-javadoc-plugin</artifactId>
            <executions>
              <execution>
                <id>attach-javadocs</id>
                <goals>
                  <goal>jar</goal>
                </goals>
              </execution>
            </executions>
          </plugin>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-gpg-plugin</artifactId>
            <version>1.5</version>
            <executions>
              <execution>
                <id>sign-artifacts</id>
                <phase>verify</phase>
                <goals>
                  <goal>sign</goal>
                </goals>
              </execution>
            </executions>
          </plugin>
        </plugins>
      </build>
    </profile>
  </profiles>
```

The second step is to define the server credentials on Travis CI. It can be done via your Travis repository [environment variables](http://docs.travis-ci.com/user/environment-variables/). Just go to the settings tab and choose the sub-tab **Environment Variables**

By default the variables you define here will be secure, and won't be shown in the build log.

So let's define two properties:

```bash
OSSRH_USER=<yourusername>
OSSRH_PASS=<yourpass>
```

AT this point, there is one last things to do; set up a `.travis.yml` in your repository.

```yaml
language: java
jdk:
  - oraclejdk7
after_success:
  - echo "<settings><servers><server><id>ossrh</id><username>\${env.OSSRH_USER}</username><password>\${env.OSSRH_PASS}</password></server></servers></settings>" > ~/settings.xml
  - mvn deploy --settings ~/settings.xml
```

In this configuration, we create a maven `settings.xml` in which we set the username and password for our server of id `ossrh`. The username and password are actually in the environment variable we define earlier. The last step is to call `mvn deploy` with this settings. In this configuration those steps will be executed after the build has been successful and the test has pass.

You can have a look at a build with a similar configuration ~~here~~ (broken link).
