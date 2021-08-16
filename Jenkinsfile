node ('lagoon-images') {
  withEnv(['AWS_BUCKET=jobs.amazeeio.services', 'AWS_DEFAULT_REGION=us-east-2']) {
    withCredentials([
      usernamePassword(credentialsId: 'aws-s3-lagoon', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY'),
      string(credentialsId: 'SKIP_IMAGE_PUBLISH', variable: 'SKIP_IMAGE_PUBLISH')
    ]) {
      try {
        env.CI_BUILD_TAG = env.BUILD_TAG.replaceAll('%2f','').replaceAll("[^A-Za-z0-9]+", "").toLowerCase()
        env.SAFEBRANCH_NAME = env.BRANCH_NAME.replaceAll('%2f','-').replaceAll("[^A-Za-z0-9]+", "-").toLowerCase()
        env.SYNC_MAKE_OUTPUT = 'target'
        // make/tests will synchronise (buffer) output by default to avoid interspersed
        // lines from multiple jobs run in parallel. However this means that output for
        // each make target is not written until the command completes.
        //
        // See `man -P 'less +/-O' make` for more information about this option.
        //
        // Uncomment the line below to disable output synchronisation.
        // env.SYNC_MAKE_OUTPUT = 'none'

        stage ('env') {
          sh "env"
        }

        deleteDir()

        stage ('Checkout') {
          def checkout = checkout scm
          env.GIT_COMMIT = checkout["GIT_COMMIT"]
        }

        // in order to have the newest images from upstream (with all the security updates) we clean our local docker cache on tag deployments
        // we don't do this all the time to still profit from image layer caching
        // but we want this on tag deployments in order to ensure that we publish images always with the newest possible images.
        if (env.TAG_NAME) {
          stage ('clean docker image cache') {
            sh script: "docker image prune -af", label: "Pruning images"
          }
        }

        stage ('build images') {
          sh script: "make docker-buildx-configure", label: "Configuring buildx for multi-platform build"
          sh script: "make -O${SYNC_MAKE_OUTPUT} -j12 build", label: "Building images"
        }

        stage ('show trivy scan results') {
          sh 'cat scan.txt'
        }

        stage ('show built images') {
          sh 'cat build.*'
          sh 'docker image ls | grep ${CI_BUILD_TAG} | sort -u'
        }

        stage ('Copy examples down') {
          sh script: "git clone https://github.com/uselagoon/lagoon-examples.git tests"
          dir ('tests') {
            sh script: "git submodule sync && git submodule update --init"
            sh script: "yarn install"
            sh script: "yarn generate-tests"
            sh script: "docker network inspect amazeeio-network >/dev/null || docker network create amazeeio-network"
          }
        }

        parallel (
          'build and push images to dockerhub': {
            stage ('push branch images to testlagoon/*') {
              withCredentials([string(credentialsId: 'amazeeiojenkins-dockerhub-password', variable: 'PASSWORD')]) {
                try {
                  if (env.SKIP_IMAGE_PUBLISH != 'true') {
                    sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
                    sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 build PUBLISH_IMAGES=true BRANCH_NAME=${SAFEBRANCH_NAME}", label: "Publishing built images to testlagoon"
                  } else {
                    sh script: 'echo "skipped because of SKIP_IMAGE_PUBLISH env variable"', label: "Skipping image publishing"
                  }
                } catch (e) {
                  echo "Something went wrong, trying to cleanup"
                  cleanup()
                  throw e
                }
              }
            }
          },
          'Run all the tests on the local images': {
            'Use correct image tags': {
              stage ('Configure and Run Tests') {
                dir ('tests') {
                  sh script: "grep -rl uselagoon . | xargs sed -i '/^FROM/ s/uselagoon/testlagoon/'"
                  sh script: "grep -rl uselagoon . | xargs sed -i '/image:/ s/uselagoon/testlagoon/'"
                  sh script: "grep -rl testlagoon . | xargs sed -i '/^FROM/ s/latest/${SAFEBRANCH_NAME}/'"
                  sh script: "grep -rl testlagoon . | xargs sed -i '/image:/ s/latest/${SAFEBRANCH_NAME}/'"
                  sh script: "find . -maxdepth 2 -name docker-compose.yml | xargs sed -i -e '/###/d'"
                }
              }
            },
            'Run simple Drupal tests': {
              stage ('Simple tests') {
                dir ('tests') {
                  sh script: "yarn test:simple"
                }
              }
            },
            'Run advanced Drupal tests': {
              stage ('Advanced tests') {
                dir ('tests') {
                  sh script: "yarn test:advanced"
                }
              }
            },
            'Run Postgres tests': {
              stage ('Postgres tests') {
                dir ('tests') {
                  sh script: "yarn test test/docker*postgres*"
                }
              }
            },
            'Replace PHP versions in simple tests': {
              stage ('Configure and Run old PHP Tests') {
                dir ('tests') {
                  sh script: "rm test/*.js"
                  sh script: "grep -rl testlagoon ./drupal8-simple/lagoon/*.dockerfile | xargs sed -i '/^FROM/ s/7.4/7.2/'"
                  sh script: "grep -rl PHP ./drupal8-simple/TESTING*.md | xargs sed -i 's/7.4/7.2/'"
                  sh script: "grep -rl testlagoon ./drupal9-simple/lagoon/*.dockerfile | xargs sed -i '/^FROM/ s/7.4/7.3/'"
                  sh script: "grep -rl PHP ./drupal9-simple/TESTING*.md | xargs sed -i 's/7.4/7.3/'"
                  sh script: "yarn generate-tests"
                }
              }
            },
            'Run simple old PHP Drupal tests': {
              stage ('Simple old PHP tests') {
                dir ('tests') {
                  sh script: "yarn test:simple"
                }
              }
            }
          }
        )

        if (env.TAG_NAME && env.SKIP_IMAGE_PUBLISH != 'true') {
          stage ('publish-amazeeio') {
            withCredentials([string(credentialsId: 'amazeeiojenkins-dockerhub-password', variable: 'PASSWORD')]) {
              sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
              sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 publish-uselagoon-baseimages", label: "Publishing built images to uselagoon"
              sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 publish-amazeeio-baseimages", label: "Publishing legacy images to amazeeio"
            }
          }
        }

        if (env.BRANCH_NAME == 'main' && env.SKIP_IMAGE_PUBLISH != 'true') {
          stage ('save images to s3') {
            sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 s3-save", label: "Saving images to AWS S3"
          }
          stage ('push latest images to testlagoon') {
            sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 publish-testlagoon-baseimages BRANCH_NAME=latest", label: "Publishing :latest images to testlagoon"
          }
        }

      } catch (e) {
        currentBuild.result = 'FAILURE'
        echo "Something went wrong, trying to cleanup"
        cleanup()
        throw e
      } finally {
        notifySlack(currentBuild.result)
      }
    }
  }

}

def cleanup() {
  try {
    sh "cat build.*"
    sh "make docker-buildx-remove"
    sh "make clean"
    sh "rm build.*"
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
