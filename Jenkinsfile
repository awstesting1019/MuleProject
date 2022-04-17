pipeline {
  agent any
    tools { 
      maven 'M2_HOME' 
      jdk 'JAVA_HOME' 
    }
  stages {
    stage('Unit Test') {
      steps {
        sh 'mvn clean test'
      }
    }
    stage('Deploy Standalone') {
      steps {
        sh 'mvn deploy -P standalone -Dmule.home=/bin/mule'
      }
    }
  }
}  
