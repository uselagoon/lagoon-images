def skipRemainingStages = false

pipeline {
  agent { label 'lagoon-images' }
  environment {
    // configure build params
    SAFEBRANCH_NAME = env.BRANCH_NAME.replaceAll('%2F','-').replaceAll('[^A-Za-z0-9]+', '-').toLowerCase()
    SAFEBRANCH_AND_BUILDNUMBER = (env.SAFEBRANCH_NAME+env.BUILD_NUMBER).replaceAll('%2f','').replaceAll('[^A-Za-z0-9]+', '').toLowerCase();
    CI_BUILD_TAG = 'lagoon'.concat(env.SAFEBRANCH_AND_BUILDNUMBER.drop(env.SAFEBRANCH_AND_BUILDNUMBER.length()-26));
    NPROC = "${sh(script:'getconf _NPROCESSORS_ONLN', returnStdout: true).trim()}"
    SKIP_IMAGE_PUBLISH = credentials('SKIP_IMAGE_PUBLISH')
    SYNC_MAKE_OUTPUT = 'target'
  }

  stages {
    stage ('env') {
      steps {
        sh 'env'
      }
    }

    // in order to have the newest images from upstream (with all the security
    // updates) we clean our local docker cache on tag deployments
    // we don't do this all the time to still profit from image layer caching
    // but we want this on tag deployments in order to ensure that we publish
    // images always with the newest possible images.
    stage ('clean docker image cache') {
      when {
        buildingTag()
      }
      steps {
        sh script: "make docker-buildx-remove", label: "removing leftover buildx"
        sh script: "docker image prune -af", label: "Pruning images"
        sh script: "docker buildx prune -af", label: "Pruning builder cache"
      }
    }

    stage ('build images') {
      steps {
        sh script: "docker run --privileged --rm tonistiigi/binfmt --install all", label: "setting binfmt correctly"
        sh script: "make docker-buildx-configure", label: "Configuring buildx for multi-platform build"
        sh script: "make docker_pull", label: "Ensuring fresh upstream images"
        sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 build", label: "Building images"
      }
    }

    stage ('show built images') {
      steps {
        sh 'cat build.txt'
        sh 'docker image ls | grep ${CI_BUILD_TAG} | sort -u'
      }
    }

    stage ('prepare tests and images') {
      parallel {
        stage ('Copy examples down') {
          steps {
            sh script: "rm -rf tests || echo 'no tests directory to remove'"
            sh script: "git clone https://github.com/uselagoon/lagoon-examples.git tests"
            dir ('tests') {
              sh script: "git submodule sync && git submodule update --init"
              sh script: "mkdir -p ./all-images && cp ../helpers/*docker-compose.yml ./all-images/ && cp ../helpers/TESTING_*_dockercompose.md ./all-images/"
              sh script: "sed -i '/image: uselagoon/ s/uselagoon/${CI_BUILD_TAG}/' ./all-images/*-docker-compose.yml"
              sh script: "yarn install"
              sh script: "docker network inspect amazeeio-network >/dev/null || docker network create amazeeio-network"
            }
          }
        }
        stage ('push amd64 branch images to testlagoon/*') {
          environment {
            PASSWORD = credentials('amazeeiojenkins-dockerhub-password')
          }
          when {
            not {
              environment name: 'SKIP_IMAGE_PUBLISH', value: 'true'
            }
          }
          steps {
            sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
            sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 publish-testlagoon-baseimages BRANCH_NAME=${SAFEBRANCH_NAME} PLATFORM='linux/amd64'", label: "Publishing built amd64 images to testlagoon"
          }
        }
      }
    }

    stage ('test and push images') {
      parallel {
        stage ('push main branch images to testlagoon/*') {
          environment {
            PASSWORD = credentials('amazeeiojenkins-dockerhub-password')
          }
          when {
            branch 'main'
            not {
              environment name: 'SKIP_IMAGE_PUBLISH', value: 'true'
            }
          }
          steps {
            retry(3) {
              sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
              sh script: "timeout 60m make -O${SYNC_MAKE_OUTPUT} -j8 build PUBLISH_IMAGES=true REGISTRY_ONE=testlagoon TAG_ONE=${SAFEBRANCH_NAME} REGISTRY_TWO=testlagoon TAG_TWO=latest PLATFORM='linux/arm64/v8'", label: "Publishing built arm64 images to testlagoon main&latest images"
            }
            retry(3) {
              sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
              sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 build PUBLISH_IMAGES=true REGISTRY_ONE=testlagoon TAG_ONE=${SAFEBRANCH_NAME} REGISTRY_TWO=testlagoon TAG_TWO=latest PLATFORM='linux/amd64,linux/arm64/v8'", label: "Publishing built digest to testlagoon main&latest images"
            }
          }
        }
        stage ('push arm64-images branch images to testlagoon/*') {
          environment {
            PASSWORD = credentials('amazeeiojenkins-dockerhub-password')
          }
          when {
            branch 'arm64-images'
            not {
              environment name: 'SKIP_IMAGE_PUBLISH', value: 'true'
            }
          }
          steps {
            retry(3) {
              sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
              sh script: "timeout 60m make -O${SYNC_MAKE_OUTPUT} -j8 build PUBLISH_IMAGES=true REGISTRY_ONE=testlagoon TAG_ONE=${SAFEBRANCH_NAME} REGISTRY_TWO=testlagoon TAG_TWO=multiarch PLATFORM='linux/arm64/v8'", label: "Publishing built arm64 images to testlagoon multiarch images"
            }
            retry(3) {
              sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
              sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 build PUBLISH_IMAGES=true REGISTRY_ONE=testlagoon TAG_ONE=${SAFEBRANCH_NAME} REGISTRY_TWO=testlagoon TAG_TWO=multiarch PLATFORM='linux/amd64,linux/arm64/v8'", label: "Publishing built digest to testlagoon multiarch images"
            }
          }
        }
        stage ('running test suite') {
          steps {
            dir ('tests') {
              sh script: "docker buildx use default", label: "Ensure to use default builder"
              sh script: "grep -rl uselagoon . | xargs sed -i '/^FROM/ s/uselagoon/${CI_BUILD_TAG}/'"
              sh script: "grep -rl uselagoon . | xargs sed -i '/image: uselagoon/ s/uselagoon/${CI_BUILD_TAG}/'"
              sh script: "find . -maxdepth 2 -name docker-compose.yml | xargs sed -i -e '/###/d'"
              sh script: "TEST=./all-images/TESTING_base_images* yarn test", label: "Run base-images tests"
              sh script: "TEST=./all-images/TESTING_service_images* yarn test", label: "Run service-images tests"
              sh script: "yarn test:simple", label: "Run simple Drupal tests"
              sh script: "yarn test:advanced", label: "Run advanced Drupal tests"
            }
          }
        }
      }
    }

    stage ('push branch images to uselagoon/*') {
      environment {
        PASSWORD = credentials('amazeeiojenkins-dockerhub-password')
      }
      when {
        buildingTag()
        not {
          environment name: 'SKIP_IMAGE_PUBLISH', value: 'true'
        }
      }
      steps {
        retry(3) {
          sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
          sh script: "timeout 60m make -O${SYNC_MAKE_OUTPUT} -j8 build PUBLISH_IMAGES=true REGISTRY_ONE=uselagoon TAG_ONE=${TAG_NAME} REGISTRY_TWO=uselagoon TAG_TWO=latest PLATFORM='linux/amd64,linux/arm64/v8'", label: "Publishing built images to uselagoon"
        }
      }
    }

    stage ('scan built images') {
      when {
        anyOf {
          branch 'main'
          buildingTag()
        }
        not {
          environment name: 'SKIP_IMAGE_PUBLISH', value: 'true'
        }
      }
      steps {
        sh script: 'make scan-images', label: "perform scan routines"
        sh script:  'find ./scans/*trivy* -type f | xargs tail -n +1', label: "Show Trivy vulnerability scan results"
        sh script:  'find ./scans/*grype* -type f | xargs tail -n +1', label: "Show Grype vulnerability scan results"
        sh script:  'find ./scans/*syft* -type f | xargs tail -n +1', label: "Show Syft SBOM results"
      }
    }
  }

  post {
    always {
      cleanup()
      deleteDir()
    }
    success {
      notifySlack('SUCCESS')
    }
    failure {
      notifySlack('FAILURE')
    }
    aborted {
      notifySlack('ABORTED')
    }
  }
}

def cleanup() {
  try {
    sh "cat build.*"
    sh "make docker-buildx-remove"
    sh "make clean"
  } catch (error) {
    echo "cleanup failed, ignoring this."
  }
}

def notifySlack(String buildStatus = 'STARTED') {
    // Build status of null means success.
    buildStatus = buildStatus ?: 'SUCCESS'

    def color

    if (buildStatus == 'STARTED') {
        color = '#68A1D1'
    } else if (buildStatus == 'SUCCESS') {
        color = '#BDFFC3'
    } else if (buildStatus == 'UNSTABLE') {
        color = '#FFFE89'
    } else {
        color = '#FF9FA1'
    }

    def msg = "${buildStatus}: `${env.JOB_NAME}` #${env.BUILD_NUMBER}:\n${env.BUILD_URL}"

    slackSend(color: color, message: msg)
}
