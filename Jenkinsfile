pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }
    stages {
        stage('clean workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout from Git') {                        
            steps {                                       
                git branch: 'main', url: 'https://github.com/yash509/DevSecOps-Python-Flask-App.git'
            }
        }
        stage('Deployments') {
            parallel {
                stage('deploy to staging') {
                    steps {
                        echo 'staging deployment done'
                    }
                }
                stage('deploy to production') {
                    steps {
                        echo 'production deployment done'
                    }
                }
            }
        }
        stage('Test Build') {
            steps {
                echo 'Building....'
            }
            post {
                always {
                    jiraSendBuildInfo site: 'clouddevopshunter.atlassian.net'
                }
            }
        }
        stage('Deploy - Staging') {
            when {
                branch 'master'
            }
            steps {
                echo 'Deploying to Staging from main....'
            }
            post {
                always {
                    jiraSendDeploymentInfo environmentId: 'us-stg-1', environmentName: 'us-stg-1', environmentType: 'staging'
                }
            }
        }
        stage('Deploy - Production') {
            when {
                branch 'master'
            }
            steps {
                echo 'Deploying to Production from main....'
            }
            post {
                always {
                    jiraSendDeploymentInfo environmentId: 'us-prod-1', environmentName: 'us-prod-1', environmentType: 'production'
                }
            }
        }
        stage("Sonarqube Analysis ") {                         
            steps {
                //dir('Band Website') {
                    withSonarQubeEnv('sonar-server') {
                    sh '''$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=python-app \
                    -Dsonar.projectKey=python-app'''
                    //}
                }
            }
        }
        stage("quality gate") {
            steps {
                //dir('Band Website') {
                    script {
                        waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
                    //}
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                //dir('Band Website') {
                    sh "npm install"
                //}
            }
        }
        stage('OWASP File System SCAN') {
            steps {
                //dir('Band Website') {
                    dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                //}
            }
        }
        stage('TRIVY File System SCAN') {
            steps {
                //dir('Band Website') {
                    sh "trivy fs . > trivyfs.txt"
                //}
            }
        }
        stage('Docker Scout File System') {
            steps {
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                       sh 'docker-scout quickview fs://.'
                       sh 'docker-scout cves fs://.'
                   }
                }   
            }
        }
        stage("Docker Image Building"){
            steps{
                script{
                    //dir('Band Website') {
                        withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){   
                            sh "docker build -t py-calc-app ." 
                            
                        //}
                    }
                }
            }
        }
        stage("Docker Image Tagging"){
            steps{
                script{
                    //dir('Band Website') {
                        withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                            sh "docker tag py-calc-app yash5090/py-calc-app:latest " 
                        //}
                    }
                }
            }
        }
        stage('Docker Image Scanning') { 
            steps { 
                sh "trivy image --format table -o trivy-image-report.html yash5090/py-calc-app:latest" 
            } 
        } 
        stage("Image Push to DockerHub") {
            steps{
                script{
                    //dir('Band Website') {
                        withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                            sh "docker push yash5090/py-calc-app:latest "
                        //}
                    }
                }
            }
        }
        stage('Docker Scout Image') {
            steps {
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                       sh 'docker-scout quickview yash5090/py-calc-app:latest'
                       sh 'docker-scout cves yash5090/py-calc-app:latest'
                       sh 'docker-scout recommendations yash5090/py-calc-app:latest'
                   }
                }   
            }
        }
        stage("TRIVY"){
            steps{
                //dir('Band Website') {
                    sh "trivy image yash5090/py-calc-app:latest > trivyimage.txt"   
                //}
            }
        }
        stage ('Manual Approval'){
          steps {
           script {
             timeout(time: 10, unit: 'MINUTES') {
              approvalMailContent = """
              Project: ${env.JOB_NAME}
              Build Number: ${env.BUILD_NUMBER}
              Go to build URL and approve the deployment request.
              URL de build: ${env.BUILD_URL}
              """
             mail(
             to: 'clouddevopshunter@gmail.com',
             subject: "${currentBuild.result} CI: Project name -> ${env.JOB_NAME}", 
             body: approvalMailContent,
             mimeType: 'text/plain'
             )
            input(
            id: "DeployGate",
            message: "Deploy ${params.project_name}?",
            submitter: "approver",
            parameters: [choice(name: 'action', choices: ['Deploy'], description: 'Approve deployment')])  
            }
           }
          }
        }
        stage('Deploy to container'){
            steps{
                //dir('BMI Calculator (JS)') {
                    sh 'docker run -d --name py-calc-app -p 3000:3000 yash5090/py-calc-app:latest' 
                //}
            }
        }
        stage('Deploy to Kubernetes'){
            steps{
                script{
                    //dir('K8S') {
                        withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'k8s', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') {
                                sh 'kubectl apply -f deployment.yaml'
                                sh 'kubectl apply -f service.yaml'
                        //}
                    }
                }
            }
        }
         stage('Verify the Kubernetes Deployments') { 
            steps { 
                withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'k8s', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') { 
                    sh "kubectl get pods " 
                    sh "kubectl get svc " 
                } 
            } 
        } 
        stage('Deployment Done') {
            steps {
                echo 'Deployed Succcessfully...'
            }
        }
    }
    post { 
        always {
            script { 
                def jobName = env.JOB_NAME 
                def buildNumber = env.BUILD_NUMBER 
                def pipelineStatus = currentBuild.result ?: 'UNKNOWN' 
                def bannerColor = pipelineStatus.toUpperCase() == 'SUCCESS' ? 'green' : 'red' 
                def body = """ 
                <html> 
                <body> 
                <div style="border: 4px solid ${bannerColor}; padding: 10px;"> 
                <h2>${jobName} - Build ${buildNumber}</h2> 
                <div style="background-color: ${bannerColor}; padding: 10px;"> 
                <h3 style="color: white;">Pipeline Status: ${pipelineStatus.toUpperCase()}</h3> 
                </div> 
                <p>Check the <a href="${BUILD_URL}">console output</a>.</p> 
                </div> 
                </body> 
                </html> 
            """ 
 
            emailext (
                subject: "${jobName} - Build ${buildNumber} - ${pipelineStatus.toUpperCase()}", 
                body: body, 
                to: 'clouddevopshunter@gmail.com', 
                from: 'jenkins@example.com', 
                replyTo: 'jenkins@example.com', 
                mimeType: 'text/html', 
                attachmentsPattern: 'trivy-image-report.html,trivyfs.txt,trivyimage.txt') 
            } 
        } 
    }
}
stage('Result') {
        timeout(time: 10, unit: 'MINUTES') {
            mail to: 'clouddevopshunter@gmail.com',
            subject: "${currentBuild.result} CI: ${env.JOB_NAME}",
            body: "Project: ${env.JOB_NAME}\nBuild Number: ${env.BUILD_NUMBER}\nGo to ${env.BUILD_URL} and approve deployment"
            input message: "Deploy ${params.project_name}?", 
            id: "DeployGate", 
            submitter: "approver", 
            parameters: [choice(name: 'action', choices: ['Success'], description: 'Approve deployment')]
        }
    }
