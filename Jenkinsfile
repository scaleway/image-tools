def images = []
def image_versions = [:]

pipeline {
  agent {
    label 'worker&&docker'
  }

  options {
    buildDiscarder(logRotator(numToKeepStr: '1'))
  }

  triggers {
    pollSCM("H */2 * * *")
    cron('H H * * H')
  }

  environment {
    SSH_KEY_FILE = "${env.HOME}/.ssh/id_worker"
    IMAGE_DIR_BASE = "${env.WORKSPACE}/image"
    EXPORT_DIR_BASE = "${env.WORKSPACE}/export"
  }

  parameters {
    booleanParam(name: 'test', defaultValue: true, description: 'Test the image')
    booleanParam(name: 'needAdminApproval', defaultValue: false, description: 'Wait for admin approval after testing')
    booleanParam(name: 'release', defaultValue: true, description: 'Release the image')
    string(name: 'logLevel', defaultValue: '3', description: 'Log level')
  }

  stages {
    stage('Pull image source') {
      steps {
        dir('image') {
          deleteDir()
          checkout([
            $class: 'GitSCM',
            poll: false,
            branches: [[name: env.IMAGE_GIT_BRANCH ?: 'master' ]],
            userRemoteConfigs: [[url: env.IMAGE_GIT_SOURCE]]
          ])
        }
      }
    }
    stage('Set environment') {
      steps {
        script {
          manifest = readFile("${env.IMAGE_DIR_BASE}/manifest.json")
          manifest_data = new groovy.json.JsonSlurperClassic().parseText(manifest)
          image_versions = manifest_data['images']
          env.IMAGE_DIR = env.IMAGE_DIR_BASE + '/' + image_versions[env.IMAGE_VERSION]['directory']
          env.MARKETPLACE_IMAGE_NAME = image_versions[env.IMAGE_VERSION]['marketplace-name']
          env.BUILD_OPTS = "--pull"
          env.LOG_LEVEL = params.logLevel
        }
      }
    }
    stage('Log into Scaleway') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'scw-test-orga-token', usernameVariable: 'SCW_ORGANIZATION', passwordVariable: 'SCW_TOKEN')]) {
          sh "scw login -o '${SCW_ORGANIZATION}' -t '${SCW_TOKEN}' -s >/dev/null 2>&1"
        }
      }
    }
    stage("Create image on Scaleway") {
      steps {
        script {
          for (String arch in image_versions[env.IMAGE_VERSION]['architectures']) {
            echo "Creating image for $arch"
            sh "make ARCH=$arch IMAGE_DIR=${env.IMAGE_DIR} EXPORT_DIR=${env.EXPORT_DIR_BASE}/$arch BUILD_OPTS='${env.BUILD_OPTS}' scaleway_image"
            script {
              imageId = readFile("${env.EXPORT_DIR_BASE}/$arch/image_id").trim()
              docker_tags = readFile("${env.EXPORT_DIR_BASE}/$arch/docker_tags").trim().split('\n')
              images.add([
                arch: arch,
                id: imageId,
                docker_tags: docker_tags
              ])
            }
          }
        }
      }
    }
    stage('Test the images') {
      when {
        expression { params.test == true }
      }
      steps {
        script {
          for (Map image : images) {
            sh "make tests IMAGE_DIR=${env.IMAGE_DIR} EXPORT_DIR=${env.EXPORT_DIR_BASE}/${image['arch']} ARCH=${image['arch']} IMAGE_ID=${image['id']} TESTS_DIR=${env.IMAGE_DIR}/tests NO_CLEANUP=${params.needAdminApproval}"
          }
          if (env.needsAdminApproval) {
            input "Confirm that the images are stable ?"
          }
        }
      }
      post {
        always {
          script {
            if (env.needsAdminApproval) {
              for (Map image : images) {
                sh "scripts/test_images.sh stop ${env.EXPORT_DIR_BASE}/${image['arch']}/${image['id']}.servers"
              }
            }
          }
        }
      }
    }
    stage('Release the image') {
      when {
        expression { params.release == true }
      }
      steps {
        script {
          for (Map image : images) {
            docker_tags = image['docker_tags'].join(' ')
            sh "docker push ${docker_tags}"
          }
          message = groovy.json.JsonOutput.toJson([
            type: "image",
            data: [
              marketplace_id: image_versions[env.IMAGE_VERSION]['marketplace-id'],
              versions: images
            ]
          ])
          versionId = input(
            message: "${message}",
            parameters: [string(name: 'version_id', description: 'ID of the new image version')]
          )
        }
        echo "Created new marketplace version of image: ${versionId}"
      }
    }
  }

  post {
    always {
      deleteDir()
      script {
        for (Map image : images) {
          docker_tag = image['docker_tags'][-1]
          sh "docker image rm ${docker_tag} && docker system prune -f"
        }
      }
    }
  }
}

