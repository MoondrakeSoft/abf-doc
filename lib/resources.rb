require 'pp'
require 'yajl/json_gem'
require 'stringio'
require 'cgi'

module GitHub
  module Resources
    module Helpers
      STATUSES = {
        200 => '200 OK',
        201 => '201 Created',
        202 => '202 Accepted',
        204 => '204 No Content',
        301 => '301 Moved Permanently',
        304 => '304 Not Modified',
        401 => '401 Unauthorized',
        403 => '403 Forbidden',
        404 => '404 Not Found',
        409 => '409 Conflict',
        422 => '422 Unprocessable Entity',
        500 => '500 Server Error'
      }

      DefaultTimeFormat = "%B %-d, %Y".freeze

      def post_date(item)
        strftime item[:created_at]
      end

      def strftime(time, format = DefaultTimeFormat)
        attribute_to_time(time).strftime(format)
      end

      def gravatar_for(login)
        %(<img height="16" width="16" src="%s" />) % gravatar_url_for(login)
      end

      def gravatar_url_for(login)
        md5 = AUTHORS[login.to_sym]
        default = "https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-user-420.png"
        "https://secure.gravatar.com/avatar/%s?s=20&d=%s" %
          [md5, default]
      end

      def headers(status, head = {})
        css_class = (status == 204 || status == 404) ? 'headers no-response' : 'headers'
        lines = ["Status: #{STATUSES[status]}"]
        head.each do |key, value|
          case key
            when :pagination
              lines << 'Link: <https://api.github.com/resource?page=2>; rel="next",'
              lines << '      <https://api.github.com/resource?page=5>; rel="last"'
            else lines << "#{key}: #{value}"
          end
        end

        lines << "X-RateLimit-Limit: 2000"
        lines << "X-RateLimit-Remaining: 499"

        %(<pre class="#{css_class}"><code>#{lines * "\n"}</code></pre>\n)
      end

      def json(key)
        hash = case key
          when Hash
            h = {}
            key.each { |k, v| h[k.to_s] = v }
            h
          when Array
            key
          else Resources.const_get(key.to_s.upcase)
        end

        hash = yield hash if block_given?

        %(<pre class="highlight"><code class="language-javascript">) +
          JSON.pretty_generate(hash) + "</code></pre>"
      end

      def text_html(response, status, head = {})
        hs = headers(status, head.merge('Content-Type' => 'text/html'))
        res = CGI.escapeHTML(response)
        hs + %(<pre class="highlight"><code>) + res + "</code></pre>"
      end
    end

    #==============================================================================
    # ABF constants
    #==============================================================================

    USER_PARTIAL =  {
      "id" => "user id",
      "uname" => "user uname",
      "name" => "user name",
      "url" => "api user path"
    }

    USER_PARTIAL_EXAMPLE = {
      "id" => 1,
      "name" => "Ivan Aivazovsky",
      "uname" => "ivan_aivazovsky",
      "url" => "/api/v1/users/1.json"
    }

    PLATFORM_PARTIAL = {
      "id" => "platform id",
      "name" => "platform name",
      "visibility" => "platform visibility",
      "platform_type" => "platform type",
      "url" => "platform data page path"
    }

    PLATFORM_PARTIAL_EXAMPLE = {
      "id" => 1,
      "name" => "rosa2012",
      "visibility" => "open",
      "platform_type" => "main",
      "url" => "/api/v1/platforms/1.json"
    }

    PROJECT_PARTIAL = {
      "id" => "project id",
      "name" => "project name",
      "visibility" => "visibility (open/hidden)",
      "fullname" => "project fullname",
      "url" => "url to project data page",
      "git_url" => "path to project git",
      "ssh_url" => "path to project git over ssh",
      'maintainer' => USER_PARTIAL.merge('email' => 'user email')
    }

    PROJECT_PARTIAL_EXAMPLE = {
      "id" => 666,
      "name" => "evil_tools",
      "visibility" => "open",
      "fullname" => "abf/evil_tools",
      "url" => "/api/v1/projects/666.json",
      "git_url" => "https:/ivan@abf.rosalinux.ru/jaroslav_garkin/hwinfo.git",
      "ssh_url" => "git@abf.rosalinux.ru:jaroslav_garkin/hwinfo.git",
      'maintainer' => USER_PARTIAL_EXAMPLE.merge('email' => 'ivan.aivazovsky@email.ru ')
    }

    ADD_MEMBER_REQUEST = {
      "member_id" => 34,
      "type" => "User"
    }

    PACKAGE_PARTIAL = {
      'id'                 => 'package id',
      'name'               => 'package name',
      'type'               => 'package type (source/binary)',
      'epoch'              => 'package epoch',
      'version'            => 'package version',
      'release'            => 'package release',
      'updated_at'         => 'package last updated date',
      'url'                => 'package url',
      'dependent_projects' => [
        PROJECT_PARTIAL.merge(
          'dependent_packages' => ['package name']
        )
      ]
    }

    PACKAGE_PARTIAL_EXAMPLE = {
        'id'                 => 1,
        'name'               => 'alpine',
        'type'               => 'binary',
        'epoch'              => 1,
        'version'            => '2.02',
        'release'            => '1',
        'updated_at'         => 1348060890,
        'url'                => 'http://file-store.rosalinux.ru/api/v1/file_stores/675bfe070075abd5b7b49ecf213e830ff2f56ae3',
        'dependent_projects' => [
          PROJECT_PARTIAL_EXAMPLE.merge(
            'dependent_packages' => %w(rpmdrake)
          )
        ]
    }

    BUILD_LIST_SHOW_EXAMPLE = {
      "build_list" =>
        {
          "id" => 10,
          "status" => 6000,
          "container_path" => "/downloads/rosa2012/container/10",
          "container_status" => 6000,
          "new_core" => true,
          "package_version" => "rosa2012.1-0.1.309-1",
          "project" => PROJECT_PARTIAL_EXAMPLE,
          "build_for_platform" => PLATFORM_PARTIAL_EXAMPLE,
          "save_to_repository" => {
            "id" => 12,
            "name" => "mr_evil/personal",
            "url" =>  "/api/v1/repositories/12.json",
            "platform" => {
              "id" => 2,
              "name" => "cocos_lts",
              "url" => "/api/v1/platforms/2.json"
            }
          },
          "arch" => {
            "id" => 1,
            "name" => "x84_64"
          },
          "created_at"            => 1349357795,
          "updated_at"            => 1349358084,
          "update_type"           => "bugfix",
          "auto_publish_status"   => 'default',
          "auto_create_container" => true,
          "use_cached_chroot"     => true,
          "use_extra_tests"       => true,
          "save_buildroot"        => false,
          "commit_hash"                 => "4edafbe69632173a1800c4d7582b60b46bc1fb55",
          "last_published_commit_hash"  => "59f606578d21683bbbf4152bcdc2ebf1dd1e2e37",
          "priority" => 0,
          "duration" => nil,
          "advisory" => {
            "id" => 666,
            "name" => "at",
            "description" => "warpc/at",
            "url" => "/api/v1/advisories/666.json"
          },
          "mass_build" => {
            "id" => 666,
            "name" => "rosa2012lts (main)",
            "url" => "/api/v1/mass_builds/666"
          },
          "user" => {
            "id" => 49,
            "name" => "Mr. Evil",
            "url" => "/api/v1/users/49.json"
          },
          "publisher" => {
            "id" => 50,
            "name" => "Mr. Good",
            "url" => "/api/v1/users/50.json"
          },
          "include_repos" => [
            {
              "id" => 16,
              "name" => "main",
              "url" => "/api/v1/repositories/16.json",
              "platform" => {
                "id" => 16,
                "name" => "warpc_personal",
                "url" => "/api/v1/platforms/16.json"
              }
            }
          ],
          "extra_repositories" => [
            {
              "id" => 17,
              "name" => "main",
              "url" => "/api/v1/repositories/17.json",
              "platform" => {
                "id" => 17,
                "name" => "avokhmin_personal",
                "url" => "/api/v1/platforms/17.json"
              }
            }
          ],
          "extra_build_lists" => [
            {
              "id"=> 12345,
              "status"=> 6000,
              "container_path" => "/downloads/warpc_personal/container/12345",
              "url" => "/api/v1/build_lists/12345.json"
            }
          ],
          'packages' => [PACKAGE_PARTIAL_EXAMPLE],
          'logs'  => [{
            'file_name' => 'abfworker::rpm-worker-859694.log',
            'size'      => '20014310',
            'url'       => 'http://file-store.rosalinux.ru/api/v1/file_stores/3a93e5553490e39b4cd50269d51ad8438b7e20b8'
          }],
          "url" => "/api/v1/build_lists/10.json"
        }
    }

    BUILD_LIST_SHOW_PARAMETERS = {
      "build_list" =>
        {
          "id" => "resource id",
          "status" => "status code",
          "container_status" => "container status code",
          "container_path" => "container path",
          "new_core" => "using new core",
          "package_version" => "package version",
          "project" => PROJECT_PARTIAL,
          "build_for_platform" => PLATFORM_PARTIAL,
          "save_to_repository" => {
            "id" => "repository for package storage id",
            "name" => "repository for package storage name",
            "url" =>  "path to repository data page",
            "platform" => {
              "id" => "repository platform id",
              "name" => "repository platform name",
              "url" => "path to repository platform data page"
            }
          },
          "arch" => {
            "id" => "build architecture id",
            "name" => "build architecture name"
          },
          "update_type"           => "update type",
          "auto_publish_status"   => "automated publising status",
          "auto_create_container" => "automated creation of container",
          "use_cached_chroot"     => "use cached chroot",
          "use_extra_tests"       => "use extra tests",
          "save_buildroot"        => "save RPM buildroot",
          "commit_hash"                 => "last commit hash of project source",
          "last_published_commit_hash"  => "last published commit hash of project source",
          "priority" => "build priority",
          "duration" => "build duration in seconds",
          "created_at" => "created at date and time",
          "updated_at" => "updated at date and time",
          "advisory" => {
            "id" => "advisory id",
            "name" => "advisory name",
            "description" => "advisory description",
            "url" => "path to advisory data page"
          },
          "mass_build" => {
            "id" => "mass_build id",
            "name" => "mass_build name",
            "url" => "path to mass_build data page"
          },
          "user" => {
            "id" => "id of user which created build",
            "name" => "user name",
            "url" => "url to user profile"
          },
          "publisher" => {
            "id" => "publisher id",
            "name" => "publisher name",
            "url" => "url to publisher profile"
          },
          "include_repos" => [
            {
              "id" => "included repository id",
              "name" => "included repository name",
              "url" => "path to included repository data page",
              "platform" => {
                "id" => "repository platform id",
                "name" => "repository platform name",
                "url" => "path to repository platform data page"
              }
            }
          ],
          "extra_repositories" => [
            {
              "id" => "extra repository id",
              "name" => "extra repository name",
              "url" => "path to extra repository data page",
              "platform" => {
                "id" => "repository platform id",
                "name" => "repository platform name",
                "url" => "path to repository platform data page"
              }
            }
          ],
          "extra_build_lists" => [
            {
              "id"=> "build list id",
              "status"=> "build list status",
              "container_path" => "container path",
              "url" => "url to build list page"
            }
          ],
          'packages' => [PACKAGE_PARTIAL],
          'logs'  => [{
            'file_name' => 'file name',
            'size'      => 'file size',
            'url'       => 'file url'
          }],
          "url" => "url to build list page"
        }
    }


    BUILD_LIST_CREATE_PARAMETERS = {
      "build_list"=> {
        "project_id"            => "project id",
        "commit_hash"           => "commit hash to build",
        "update_type"           => "one of the update types",
        "save_to_repository_id" => "repository identifier for package storage",
        "build_for_platform_id" => "platform identifier of platform for build",
        "auto_publish_status"   => "automated publising status",
        "auto_create_container" => "automated creation of container",
        "use_cached_chroot"     => "use cached chroot",
        "use_extra_tests"       => "use extra tests",
        "save_buildroot"        => "save RPM buildroot",
        "external_nodes"        => "external nodes",
        "include_testing_subrepository" => "include 'testing' subrepository",
        "include_repos"=> [
          "included repository id for each selected platform"
        ],
        "extra_repositories"=> [
          "extra repository id for each selected platform"
        ],
        "extra_build_lists"=> [
          "extra build list id with container for each selected platform"
        ],
        "arch_id"=> "architecture identifier"
      }
    }

    BUILD_LIST_CREATE_EXAMPLE = {
      "build_list"=> {
        "project_id"            => "10",
        "commit_hash"           => "751b0cad9cd1467e735d8c3334ea3cf988995fab",
        "update_type"           => "bugfix",
        "save_to_repository_id" => 12,
        "build_for_platform_id" => 2,
        "auto_publish_status"   => 'default',
        "auto_create_container" => true,
        "use_cached_chroot"     => true,
        "use_extra_tests"       => true,
        "save_buildroot"        => false,
        "external_nodes"        => nil,
        "include_testing_subrepository" => false,
        "include_repos"=> [
          54,
          53
        ],
        "extra_repositories"=> [
          56,
          55
        ],
        "extra_build_lists" => [
          12345,
          12346
        ],
        "arch_id"=> 1
      }
    }

    BUILD_LIST_CREATE_RESPONSE = {
      "build_list" => {
        "id"      => "build list id (null if failed)",
        "message" => "success or fail message"
      }
    }

    BUILD_LIST_CREATE_RESPONSE_EXAMPLE = {
      "build_list"=> {
        "id"      => 56,
        "message" => "Build list for project version 'beta_2012', platform 'rosa2012' and architecture 'i586' has been created successfully"
      }
    }

    BUILD_LIST_CANCEL_RESPONSE = {
      "build_list"=> {
        "id"      => "build list id (null if failed)",
        "message" => "success or fail message"
      }
    }

    BUILD_LIST_CANCEL_RESPONSE_EXAMPLE = {
      "build_list" => {
        "id"      => 10,
        "message" => "Build canceled"
      }
    }

    BUILD_LIST_CANCEL_RESPONSE_EXAMPLE2 = {
      "build_list" => {
        "id"      => nil,
        "message" => "Errors during build cancelation!"
      }
    }

    BUILD_LIST_PUBLISH_RESPONSE = {
      "build_list" => {
        "id"      => "build list id (null if failed)",
        "message" => "success or fail message"
      }
    }

    BUILD_LIST_PUBLISH_RESPONSE_EXAMPLE = {
      "build_list" => {
        "id"      => 10,
        "message" => "Build is queued for publishing"
      }
    }

    BUILD_LIST_PUBLISH_RESPONSE_EXAMPLE2 = {
      "build_list" => {
        "id"      => nil,
        "message" => "Errors during build publishing!"
      }
    }

    BUILD_LIST_RERUN_TESTS_RESPONSE = {
      "build_list" => {
        "id"      => "build list id (null if failed)",
        "message" => "success or fail message"
      }
    }

    BUILD_LIST_RERUN_TESTS_RESPONSE_EXAMPLE = {
      "build_list" => {
        "id"      => 10,
        "message" => "Build is queued for rerun tests"
      }
    }

    BUILD_LIST_RERUN_TESTS_RESPONSE_EXAMPLE2 = {
      "build_list" => {
        "id"      => nil,
        "message" => "Errors during rerun tests!"
      }
    }

    BUILD_LIST_CREATE_CONTAINER_RESPONSE = {
      "build_list" => {
        "id"      => "build list id (null if failed)",
        "message" => "success or fail message"
      }
    }

    BUILD_LIST_CREATE_CONTAINER_RESPONSE_EXAMPLE = {
      "build_list" => {
        "id"      => 10,
        "message" => "Container is queued for creating"
      }
    }

    BUILD_LIST_CREATE_CONTAINER_RESPONSE_EXAMPLE2 = {
      "build_list" => {
        "id"      => nil,
        "message" => "Errors during container creating!"
      }
    }

    BUILD_LIST_REJECT_RESPONSE = {
      "build_list" => {
        "id"      => "build list id (null if failed)",
        "message" => "success or fail message"
      }
    }

    BUILD_LIST_REJECT_RESPONSE_EXAMPLE = {
      "build_list" => {
        "id"      => 10,
        "message" => "Build is rejected"
      }
    }

    BUILD_LIST_REJECT_RESPONSE_EXAMPLE2 = {
      "build_list" => {
        "id"      => nil,
        "message" => "Errors during build rejecting!"
      }
    }

    BUILD_LIST_SEARCH_RESPONSE = {
      "build_lists"=> [
        {
          "id"=> "build list id",
          "status"=> "build list status",
          "project_id" => "project id",
          "url"=> "build list page"
        }
      ],
      "url"=> "current url for build lists page"
    }

    BUILD_LIST_SEARCH_RESPONSE_EXAMPLE = {
      "build_lists"=> [
        {
          "id"=> 25,
          "status"=> 6000,
          "project_id" => 10,
          "url"=> "/api/v1/build_lists/25.json"
        },
        {
          "id"=> 26,
          "status"=> 6000,
          "project_id" => 20,
          "url"=> "/api/v1/build_lists/26.json"
        }
      ],
      "url"=> "/api/v1/build_lists.json"
    }

    ERROR_404 = {
      "status"=> 404,
      "message"=> "Error 404. Resource not found!"
    }

    ERROR_500 = {
      "status"=> 500,
      "message"=> "Something went wrong. We've been notified about this issue and we'll take a look at it shortly."
    }

    ERROR_503 = {
      "status"=> 503,
      "message"=> "We update the site, it will take some time. We are really trying to do it fast. We apologize for any inconvenience.."
    }

    ERROR_403 = {
      "message"=> "Access violation to this page!"
    }

    ERROR_AUTH = {
      "error" => "You need to sign in or sign up before continuing."
    }

    ERROR_WRONG_PASS = {
      "error" => "Invalid email or password."
    }

    ERROR_RATE_LIMIT = {
      "message" => "403 Forbidden | Rate Limit Exceeded"
    }

    PROJECT_PARAMS = PROJECT_PARTIAL.merge({
      "description" => "description",
      "ancestry" => "project ancestry",
      "has_issues" => "true if issues enabled",
      "has_wiki" => "true if wiki enabled",
      "default_branch" => "git branch used by default",
      "is_package" => "true if project is package",
      "publish_i686_into_x86_64" => "true if i686 packages will be also published into x86_64 repository",
      "created_at" => "created at date and time",
      "updated_at" => "updated at date and time",
      "owner" => {
        "id" => "owner id",
        "name" => "owner name",
        "type" => "owner type",
        "url" => "path to owner data"
      }
    })

    PROJECT_PARAMS_EXAMPLE = PROJECT_PARTIAL_EXAMPLE.merge({
      "description" => "bla-bla-bla",
      "ancestry" => nil,
      "has_issues" => true,
      "has_wiki" => false,
      "default_branch" => "master",
      "is_package" => true,
      "publish_i686_into_x86_64" => false,
      "created_at" => 1348168705,
      "updated_at" => 1348168905,
      "owner" => {
        "id" => 4,
        "name" => "Yaroslav Garkin",
        "type" => "User",
        "url" => "/api/v1/users/4.json"
      }
    })

    PROJECT_LIST_RESPONSE = {
      "projects" => [PROJECT_PARAMS],
      "url" => "path to projects data"
    }

    PROJECT_LIST_RESPONSE_EXAMPLE = {
      "projects" => [PROJECT_PARAMS_EXAMPLE],
      "url" => "/api/v1/projects.json"
    }

    PROJECT_DATA_RESPONSE = {
      "project"=> PROJECT_PARAMS.merge({
        "project_statistics" => [
          {
            "average_build_time"  => "average build time for this project (sec.)",
            "build_count"         => "count of builds",
            "arch_id"             => "architecture of build lists"
          }
        ],
        "maintainer" => {
          "id" => "maintainer id",
          "name" => "maintainer name",
          "uname" => "maintainer uname",
          "url" => "path to owner data"
        },
        "repositories" => [
          {
            "id" => "repository for package storage id",
            "name" => "repository for package storage name",
            "url" => "path to repository data page",
            "platform" => {
              "id" => "repository platform id",
              "name" => "repository platform name",
              "url" => "path to repository platform data page"
            }
          }
        ]
      })
    }

    PROJECT_DATA_RESPONSE_EXAMPLE = {
      "project" => PROJECT_PARAMS_EXAMPLE.merge({
        "project_statistics" => [
          {
            "average_build_time"  => 100,
            "build_count"         => 3,
            "arch_id"             => 1
          },
          {
            "average_build_time"  => 555,
            "build_count"         => 7,
            "arch_id"             => 2
          },
        ],
        "maintainer" => {
          "id" => 4,
          "name" => "Yaroslav Garkin",
          "uname" => "yaroslav_garkin",
          "url" => "/api/v1/users/4.json"
        },
        "repositories" => [
          {
            "id" => 1,
            "name" => "main",
            "url" => "/api/v1/repositories/1.json",
            "platform" => {
              "id" => 1,
              "name" => "mdv_main",
              "url" => "/api/v1/platforms/1.json"
            }
          },
          {
            "id" => 3,
            "name" => "main",
            "url" => "/api/v1/repositories/3.json",
            "platform" => {
              "id" => 3,
              "name" => "warpc_personal",
              "url" => "/api/v1/platforms/3.json"
            }
          }
        ]
      })
    }

    PROJECT_GET_ID_RESPONSE = {
      "project" =>
        {
          "id" => "resource id",
          "name" => "name",
          "fullname" => "fullname",
          "visibility" => "visibility (open/hidden)",
          "owner" => {
            "id" => "owner id",
            "name" => "owner name",
            "url" => "url to owner profile"
          },
          "url" => "url to project data page",
          "git_url" => "path to project git"
        }
    }

    PROJECT_GET_ID_RESPONSE_EXAMPLE = {
      "project" =>
        {
          "id" => 4661,
          "name" => "hwinfo",
          "fullname" => "jaroslav_garkin/hwinfo",
          "visibility" => "open",
          "owner" => {
            "id" => 4,
            "name" => "Yaroslav Garkin",
            "type" => "User",
            "url" => "/api/v1/users/4.json"
          },
          "url" => "/api/v1/projects/4661.json",
          "git_url" => "https:/ivan@abf.rosalinux.ru/jaroslav_garkin/hwinfo.git"
        }
    }


    PROJECT_REFS_LIST_RESPONSE = {
      "refs_list" => [
        {
          "ref" => "reference",
          "object" => {
            "type" => "type of reference (tag or commit)",
            "sha" => "sha"
          }
        }
      ],
      "url" => "url to project refs_list page"
    }
    PROJECT_REFS_LIST_RESPONSE_EXAMPLE = {
      "refs_list" => [
        {
          "ref" => "master",
          "object" => {
            "type" => "commit",
            "sha" => "3d1468bbb339c8b59234a5bbc35dedf3d89c2043"
          }
        },
        {
          "ref" => "v.0.0.1",
          "object" => {
            "type" => "tag",
            "sha" => "3d5d7af0e429ecad2b0b1b752235cdd0f9d51a6f"
          }
        },
      ],
      "url" => "/api/v1/projects/667/refs_list.json"
    }

    PROJECT_UPDATE_EXAMPLE = {
      "name" => "project_name",
      "description" => "description",
      "has_issues" => true,
      "has_wiki" => false,
      "maintainer_id" => 15,
      "visibility" => "open",
      "is_package" => true,
      "default_branch" => "master",
      "publish_i686_into_x86_64" => false
    }

    PROJECT_UPDATE_REQUEST = {
      "project" => PROJECT_UPDATE_EXAMPLE
    }

    PROJECT_UPDATE_RESPONSE = {
      "project" => {
        "id" => "project id (null if failed)",
        "message" => "success or fail message"
      }
    }

    PROJECT_UPDATE_RESPONSE_EXAMPLE = {
      "project" => {
        "id" => 12,
        "message" => "Project has been updated successfully"
      }
    }

    PROJECT_CREATE_REQUEST = {
      "project" => PROJECT_UPDATE_EXAMPLE.merge({
        "owner_id" => 56,
        "owner_type" => "Group"
      })
    }
    PROJECT_CREATE_RESPONSE = PROJECT_UPDATE_RESPONSE
    PROJECT_CREATE_RESPONSE_EXAMPLE = {
      "project" => {
        "id" => 12,
        "message" => "Project has been created successfully"
      }
    }

    PROJECT_DESTROY_RESPONSE = PROJECT_UPDATE_RESPONSE
    PROJECT_DESTROY_RESPONSE_EXAMPLE = {
      "project" => {
        "id" => 12,
        "message" => "Project has been destroyed successfully"
      }
    }

    PROJECT_FORK_REQUEST = {
      "group_id" => 15
    }
    PROJECT_FORK_RESPONSE = PROJECT_UPDATE_RESPONSE
    PROJECT_FORK_RESPONSE_EXAMPLE = {
      "project" => {
        "id" => 12,
        "message" => "Project has been forked successfully"
      }
    }

    PROJECT_MEMBERS_RESPONSE = {
      "project" =>
        {
          "id" => "project id",
          "members" => [
            {
              "id" => "member id",
              "type" => "User or Group type of member",
              "url" => "member path"
            }
          ]
        },
      "url" => "members path"
    }

    PROJECT_MEMBERS_RESPONSE_EXAMPLE = {
      "project" =>
        {
          "id" => 77,
          "members" => [
            {
              "id" => 31,
              "type" => "User",
              "url" => "/api/v1/users/31.json"
            },
            {
              "id" => 22,
              "type" => "Group",
              "url" => "/api/v1/groups/31.json"
            }
          ]
        },
      "url" => "/api/v1/projects/77/members.json"
    }

    PROJECT_ADD_MEMBER_REQUEST = ADD_MEMBER_REQUEST.merge({
      "role" => "admin"
    })
    PROJECT_ADD_MEMBER_RESPONSE = PROJECT_UPDATE_RESPONSE
    PROJECT_ADD_MEMBER_RESPONSE_EXAMPLE = {
      "project"=>
        {
          "id"=> 56,
          "message"=> "User '32' has been added to project successfully"
        }
    }
    PROJECT_ADD_MEMBER_RESPONSE_EXAMPLE2 = {
      "project"=>
        {
          "id"=> 56,
          "message"=> "Group '31' has been added to project successfully"
        }
    }

    PROJECT_REMOVE_MEMBER_REQUEST = ADD_MEMBER_REQUEST
    PROJECT_REMOVE_MEMBER_RESPONSE = PROJECT_UPDATE_RESPONSE
    PROJECT_REMOVE_MEMBER_RESPONSE_EXAMPLE = {
      "project"=>
        {
          "id"=> 56,
          "message"=> "User '32' has been removed from project successfully"
        }
    }
    PROJECT_REMOVE_MEMBER_RESPONSE_EXAMPLE2 = {
      "project"=>
        {
          "id"=> 56,
          "message"=> "Group '31' has been removed from project successfully"
        }
    }

    PROJECT_UPDATE_MEMBER_REQUEST = PROJECT_ADD_MEMBER_REQUEST
    PROJECT_UPDATE_MEMBER_RESPONSE = PROJECT_UPDATE_RESPONSE
    PROJECT_UPDATE_MEMBER_RESPONSE_EXAMPLE = {
      "project"=>
        {
          "id"=> 56,
          "message"=> "Role for user '34' has been updated in project successfully"
        }
    }
    PROJECT_UPDATE_MEMBER_RESPONSE_EXAMPLE2 = {
      "project"=>
        {
          "id"=> 56,
          "message"=> "Role for group '31' has been updated in project successfully"
        }
    }

    REPOSITORY_UPDATE_EXAMPLE = {
      "description" => "description",
      "publish_without_qa" => true,
      "publish_builds_only_from_branch" => "platform_name"
    }

    REPOSITORY_DATA_RESPONSE = {
      "repository" => {
        "id" => "resource id",
        "name" => "name",
        "created_at" => "created at date and time",
        "updated_at" => "updated at date and time",
        "description" => "description",
        "publish_without_qa" => "publication without QA",
        "publish_builds_only_from_branch" => "platform name",
        "platform" => PLATFORM_PARTIAL,
        "url" => "url to repository resource"
      }
    }

    REPOSITORY_DATA_RESPONSE_EXAMPLE = {
      "repository" => {
        "id" => 30,
        "name" => "main",
        "created_at" => 1346762587,
        "updated_at" => 1346841731,
        "platform" => PLATFORM_PARTIAL_EXAMPLE,
        "url" => "/api/v1/repositories/30.json"
      }.merge(REPOSITORY_UPDATE_EXAMPLE)
    }

    REPOSITORY_PROJECTS_RESPONSE = {
      "repository" => {
        "id" => "resource id",
        "name" => "repository name",
        "url" => "url to repository resource",
        "projects" => [PROJECT_PARTIAL]
      },
      "url" => "url to projects data"
    }

    REPOSITORY_PROJECTS_RESPONSE_EXAMPLE = {
      "repository" => {
        "id" => 30,
        "name" => "main",
        "url" => "/api/v1/repositories/30.json",
        "projects" => [PROJECT_PARTIAL_EXAMPLE]
      },
      "url" => "/api/v1/repositories/30/projects.json"
    }

    REPOSITORY_UPDATE_REQUEST = {
      "repository" => REPOSITORY_UPDATE_EXAMPLE
    }

    REPOSITORY_UPDATE_RESPONSE = {
      "repository" =>
        {
          "id" => "repository id (null if failed)",
          "message" => "success or fail message"
        }
    }

    REPOSITORY_UPDATE_RESPONSE_EXAMPLE = {
      "repository" =>
      {
        "id" => 12,
        "message" => "Repository has been updated successfully"
      }
    }

    REPOSITORY_CREATE_REQUEST = {
      "repository" => REPOSITORY_UPDATE_EXAMPLE.merge({
        "platform_id" => 15,
        "name" => "repository name"
      })
    }

    REPOSITORY_CREATE_RESPONSE = REPOSITORY_UPDATE_RESPONSE
    REPOSITORY_CREATE_RESPONSE_EXAMPLE = {
      "repository" =>
      {
        "id" => 12,
        "message" => "Repository has been created successfully"
      }
    }

    REPOSITORY_DESTROY_RESPONSE = REPOSITORY_UPDATE_RESPONSE
    REPOSITORY_DESTROY_RESPONSE_EXAMPLE = {
      "repository" =>
      {
        "id" => 12,
        "message" => "Repository has been destroyed successfully"
      }
    }

    REPOSITORY_ADD_MEMBER_REQUEST = ADD_MEMBER_REQUEST
    REPOSITORY_ADD_MEMBER_RESPONSE = REPOSITORY_UPDATE_RESPONSE
    REPOSITORY_ADD_MEMBER_RESPONSE_EXAMPLE = {
      "repository"=>
        {
          "id"=> 56,
          "message"=> "User '32' has been added to repository successfully"
        }
    }
    REPOSITORY_ADD_MEMBER_RESPONSE_EXAMPLE2 = {
      "repository"=>
        {
          "id"=> 56,
          "message"=> "Group '31' has been added to repository successfully"
        }
    }

    REPOSITORY_REMOVE_MEMBER_REQUEST = ADD_MEMBER_REQUEST
    REPOSITORY_REMOVE_MEMBER_RESPONSE = REPOSITORY_UPDATE_RESPONSE
    REPOSITORY_REMOVE_MEMBER_RESPONSE_EXAMPLE = {
      "repository"=>
        {
          "id"=> 56,
          "message"=> "User '32' has been removed from repository successfully"
        }
    }
    REPOSITORY_REMOVE_MEMBER_RESPONSE_EXAMPLE2 = {
      "repository"=>
        {
          "id"=> 56,
          "message"=> "Group '31' has been removed from repository successfully"
        }
    }

    ADD_PROJECT_REQUEST = { "project_id" => 34 }
    REPOSITORY_ADD_PROJECT_REQUEST = ADD_PROJECT_REQUEST
    REPOSITORY_ADD_PROJECT_RESPONSE = REPOSITORY_UPDATE_RESPONSE
    REPOSITORY_ADD_PROJECT_RESPONSE_EXAMPLE = {
      "repository"=>
        {
          "id"=> 56,
          "message"=> "Project '32' has been added to repository successfully"
        }
    }

    REPOSITORY_REMOVE_PROJECT_REQUEST = ADD_PROJECT_REQUEST
    REPOSITORY_REMOVE_PROJECT_RESPONSE = REPOSITORY_UPDATE_RESPONSE
    REPOSITORY_REMOVE_PROJECT_RESPONSE_EXAMPLE = {
      "repository"=>
        {
          "id"=> 56,
          "message"=> "Project '32' has been removed from repository successfully"
        }
    }

    REPOSITORY_SIGNATURES_REQUEST = {
      "repository"=>
        {
          "public"=> "public key",
          "secret"=> "secret key"
        }
    }
    REPOSITORY_SIGNATURES_RESPONSE = REPOSITORY_UPDATE_RESPONSE
    REPOSITORY_SIGNATURES_RESPONSE_EXAMPLE = {
      "repository"=>
        {
          "id"=> 56,
          "message"=> "Signatures have been updated for repository successfully"
        }
    }

    REPOSITORY_ADD_REPO_LOCK_FILE_RESPONSE = REPOSITORY_UPDATE_RESPONSE
    REPOSITORY_ADD_REPO_LOCK_FILE_RESPONSE_EXAMPLE = {
      "repository"=>
        {
          "id"=> 56,
          "message"=> "'.repo.lock' file has been added to repository successfully"
        }
    }

    REPOSITORY_REMOVE_REPO_LOCK_FILE_RESPONSE = REPOSITORY_UPDATE_RESPONSE
    REPOSITORY_REMOVE_REPO_LOCK_FILE_RESPONSE_EXAMPLE = {
      "repository"=>
        {
          "id"=> 56,
          "message"=> "'.repo.lock' file has been removed from repository successfully"
        }
    }

    PRODUCT_PARTIAL = {
      'id' => 'resource id',
      'name' => 'name',
      'description' => 'description',
      'main_script' => 'main script',
      'params' => 'params for running script',
      'time_living' => 'Max time for building (in minutes)',
      'autostart_status' => 'status of autostart ISO builds',
      'url' => 'url to product page'
    }

    PRODUCT_PARTIAL_EXAMPLE = {
      'id' => '1',
      'name' => 'rosa2012lts_ee',
      'description' => 'Extended Edition ROSA 2012 Marathon with non-free and restricted',
      'main_script' => 'MATRIX',
      'params' => 'lst=libs externalarch=\"x86_64\" PRODUCTNAME=ROSA.201...',
      'time_living' => '60',
      'autostart_status' => nil,
      'url' => '/api/v1/products/10.json'
    }

    PLATFORM_DATA_RESPONSE = {
      "platform" => {
        "id" => "platform id",
        "name" => "platform name",
        "description" => "platform description",
        "parent_platform_id" => "parent platform id",
        "created_at" => "platform created at",
        "updated_at" => "platform updated_at",
        "released" => "platform released",
        "visibility" => "platform visibility",
        "platform_type" => "platform type",
        "distrib_type" => "platform distribution type",
        "default_branch" => "platform default branch",
        "owner" => {
          "id" => "owner id",
          "name" => "owner name",
          "type" => "owner type",
          "url" => "owner data path"
        },
        "repositories" => [
          {
            "id" => "repository for package storage id",
            "name" => "repository for package storage name",
            "url" => "path to repository data page"
          }
        ],
        "products" => [PRODUCT_PARTIAL],
        "url" => "platform path"
      }
    }

    PLATFORM_DATA_RESPONSE_EXAMPLE = {
      "platform" => {
        "id" => 1,
        "name" => "mdv",
        "description" => "mdv_main",
        "parent_platform_id" => nil,
        "created_at" => "1326990586" ,
        "updated_at" => "1337171843",
        "released" => true,
        "visibility" => "open",
        "platform_type" => "main",
        "distrib_type" => "mdv",
        "default_branch" => "master",
        "owner" => {
          "id" => 5,
          "name" => "Timothy Bobrov",
          "type" => "User",
          "url" => "/api/v1/users/5.json"
        },
        "repositories" => [
          {
            "id" => 1,
            "name" => "main",
            "url" => "/api/v1/repositories/1.json"
          },
          {
            "id" => 2,
            "name" => "release",
            "url" => "/api/v1/repositories/2.json"
          }
        ],
        "products" => [PRODUCT_PARTIAL_EXAMPLE],
        "url" => "/api/v1/platforms/1.json"
      }
    }

    PLATFORM_OPTIONS_FOR_UPDATE = {
      "default branch" => 'new_branch',
      "description" => "new description",
      "released" => true,
      "owner_id" => 1
    }
    PLATFORM_UPDATE_REQUEST = {
      "platform" => PLATFORM_OPTIONS_FOR_UPDATE
    }

    PLATFORM_UPDATE_RESPONSE = {
      "platform" =>
        {
          "id" => "platform id (null if failed)",
          "message" => "success or fail message"
        }
    }

    PLATFORM_UPDATE_RESPONSE_EXAMPLE = {
      "platform"=>
        {
          "id"=> 56,
          "message"=> "Platform has been updated successfully"
        }
    }

    PLATFORM_CREATE_REQUEST = {
      "platform" => PLATFORM_OPTIONS_FOR_UPDATE.merge({
        "name" => "distrib_type",
        "distrib_type" => "mdv"
      })
    }
    PLATFORM_CREATE_RESPONSE = PLATFORM_UPDATE_RESPONSE
    PLATFORM_CREATE_RESPONSE_EXAMPLE = {
      "platform"=>
        {
          "id"=> 56,
          "message"=> "Platform has been created successfully"
        }
    }

    PLATFORM_MEMBERS_RESPONSE = {
      "platform" =>
        {
          "id" => "platform id",
          "members" => [
            {
              "id" => "member id",
              "type" => "User or Group type of member",
              "url" => "member path"
            }
          ]
        },
      "url" => "members path"
    }

    PLATFORM_MEMBERS_RESPONSE_EXAMPLE = {
      "platform" =>
        {
          "id" => 77,
          "members" => [
            {
              "id" => 31,
              "type" => "User",
              "url" => "/api/v1/users/31.json"
            },
            {
              "id" => 22,
              "type" => "Group",
              "url" => "/api/v1/groups/31.json"
            }
          ]
        },
      "url" => "/api/v1/platforms/77/members.json"
    }

    PLATFORM_ADD_MEMBER_REQUEST = ADD_MEMBER_REQUEST

    PLATFORM_ADD_MEMBER_RESPONSE = PLATFORM_UPDATE_RESPONSE

    PLATFORM_ADD_MEMBER_RESPONSE_EXAMPLE = {
      "platform"=>
        {
          "id"=> 56,
          "message"=> "User '32' has been added to platform successfully"
        }
    }

    PLATFORM_ADD_MEMBER_RESPONSE_EXAMPLE2 = {
      "platform"=>
        {
          "id"=> 56,
          "message"=> "Group '31' has been added to platmorm successfully"
        }
    }

    PLATFORM_REMOVE_MEMBER_REQUEST = ADD_MEMBER_REQUEST

    PLATFORM_REMOVE_MEMBER_RESPONSE = PLATFORM_UPDATE_RESPONSE

    PLATFORM_REMOVE_MEMBER_RESPONSE_EXAMPLE = {
      "platform"=>
        {
          "id"=> 56,
          "message"=> "User '32' has been removed from platform successfully"
        }
    }

    PLATFORM_REMOVE_MEMBER_RESPONSE_EXAMPLE2 = {
      "platform"=>
        {
          "id"=> 56,
          "message"=> "Group '31' has been removed from platform successfully"
        }
    }

    PLATFORM_CLONE_REQUEST = {
      "platform" =>
        {
          "default_branch" => "master",
          "description" => "platform description",
          "name" => "platform name"
        }
    }

    PLATFORM_CLONE_RESPONSE = PLATFORM_UPDATE_RESPONSE
    PLATFORM_CLONE_RESPONSE_EXAMPLE = {
      "platform"=>
        {
          "id"=> 56,
          "message"=> "Platform has been cloned successfully"
        }
    }

    PLATFORM_DESTROY_RESPONSE = PLATFORM_UPDATE_RESPONSE
    PLATFORM_DESTROY_RESPONSE_EXAMPLE = {
      "platform"=>
        {
          "id"=> 56,
          "message"=> "Platform has been destroyed successfully"
        }
    }

    PLATFORM_CLEAR_RESPONSE = PLATFORM_UPDATE_RESPONSE
    PLATFORM_CLEAR_RESPONSE_EXAMPLE = {
      "platform"=>
        {
          "id"=> 56,
          "message"=> "Platform has been cleared successfully"
        }
    }

    PLATFORM_FOR_LIST_OR_FOR_BUILD = {
      "id" => "platform id",
      "name" => "platform name",
      "platform_type" => "platform type(main/personal)",
      "visibility" => "platform visibility (hidden/open)",
      "owner" =>{
        "id" => "owner id",
        "name" => "owner name",
        "type" => "owner type",
        "url" => "path to owner data"
      },
      "repositories" => [
        {
          "id" => "repository for package storage id",
          "name" => "repository for package storage name",
          "url" => "path to repository data page"
        }
      ],
      "url" => "path to platform data"
    }

    PLATFORMS_FOR_LIST_OR_FOR_BUILD_EXAMPLE = [
      {
        "id" => 16,
        "name" => "rosa2012",
        "platform_type" => "main",
        "visibility" => "open",
        "owner" => {
          "id" => 5,
          "name" => "Timothy Bobrov1",
          "type" => "User",
          "url" => "/api/v1/users/5.json"
        },
        "repositories" => [
          {
            "id" => 26,
            "name" => "main",
            "url" => "/api/v1/repositories/26.json"
          },
          {
            "id" => 27,
            "name" => "contrib",
            "url" => "/api/v1/repositories/27.json"
          }
        ],
        "url" => "/api/v1/platforms/26.json"
      },
      {
        "id" => 18,
        "name" => "timothy_tsvetkov",
        "platform_type" => "main",
        "visibility" => "open",
        "owner" => {
          "id" => 4,
          "name" => "Yaroslav Garkin",
          "type" => "User",
          "url" => "/api/v1/users/4.json"
        },
        "repositories" => [
          {
            "id" => 30,
            "name" => "main",
            "url" => "/api/v1/repositories/30.json"
          },
          {
            "id" => 31,
            "name" => "non-free",
            "url" => "/api/v1/repositories/31.json"
          }
        ],
      "url" => "/api/v1/platforms/18.json"
      }
    ]

    PLATFORM_LIST_RESPONSE = {
      "platforms" => [PLATFORM_FOR_LIST_OR_FOR_BUILD],
      "url" => "path to platforms data"
    }

    PLATFORM_LIST_RESPONSE_EXAMPLE = {
      "platforms" => (PLATFORMS_FOR_LIST_OR_FOR_BUILD_EXAMPLE.clone <<   {
        "id" => 17,
        "name" => "timothy_bobrov_personal",
        "platform_type" => "personal",
        "visibility" => "open",
        "owner" => {
          "id" => 5,
          "name" => "Timothy Bobrov",
          "type" => "User",
          "url" => "/timothy_bobrov.json"
        },
        "repositories" => [
          {
            "id" => 28,
            "name" => "main",
            "url" => "/api/v1/repositories/28.json"
          },
        ],
        "url" => "/api/v1/platforms/17.json"
      }),
      "url" => "/api/v1/platforms.json"
    }

    PLATFORM_FOR_BUILD_RESPONSE = {
      "platforms" => [PLATFORM_FOR_LIST_OR_FOR_BUILD.merge({
        "platform_type" => "platform type(only main for build task)",
        "visibility" => "platform visibility (only open if the current user is anonymous)"
      })],
      "url" => "path to platforms data"
    }

    PLATFORM_FOR_BUILD_RESPONSE_EXAMPLE = {
      "platforms" => PLATFORMS_FOR_LIST_OR_FOR_BUILD_EXAMPLE,
      "url" => "/api/v1/platforms/platforms_for_build.json"
    }

    ARCHITECTURE_LIST_RESPONSE = {
      "architectures" => [
        {
          "id" => "architecture identifier",
          "name" => "architecture name"
        }
      ]
    }

    ARCHITECTURE_LIST_RESPONSE_EXAMPLE = {
      "architectures" => [
        {
          "id" => 1,
          "name" => "x86_64"
        },
        {
          "id" => 2,
          "name" => "i586"
        }
      ]
    }

    USER_UPDATE_PARAMS = {
      "name" => "user name",
      "email" => "user email",
      "language" => "user language",
      "professional_experience" => "user professional experience",
      "site" => "user site",
      "company" => "user company",
      "location" => "user location"
    }

    USER_DATA_RESPONSE = {
      "user" => USER_UPDATE_PARAMS.merge({
        "id" => "user id",
        "uname" => "user uname",
        "own_projects_count" => "count of own projects",
        "build_priority" => "build priority",
        "created_at" => "user created at",
        "updated_at" => "user updated_at",
        "avatar_url" => "avatar url",
        "url" => "api user path",
        "html_url"=> "html user path"
      })
    }

    USER_DATA_RESPONSE_EXAMPLE = {
      "user" =>  {
        "id" => 1,
        "name" => "Ivan Aivazovsky",
        "uname" => "ivan_aivazovsky",
        "email" => "ivan_aivazovsky@test.com",
        "language" => "ru",
        "own_projects_count" => 3,
        "professional_experience" => "software developer",
        "site" => "http://abf.rosalinux.ru/",
        "company" => "ROSA, CJSC",
        "location" => "Saint Petersburg",
        "avatar_url" => "avatar url",
        "build_priority" => 50,
        "created_at" => 1349357795,
        "updated_at" => 1349358084,
        "url" => "/api/v1/users/1.json",
        "html_url"=> "/ivan_aivazovsky"
      }
    }

    CURRENT_USER_DATA_RESPONSE = {
      'user' => USER_DATA_RESPONSE.merge({'role' => 'user role (nil/admin/tester/system)'})
    }

    CURRENT_USER_DATA_RESPONSE_EXAMPLE = {
      'user' => USER_DATA_RESPONSE_EXAMPLE.merge({'role' => ''})
    }

    USER_UPDATE_REQUEST = {
      "user" => USER_UPDATE_PARAMS
    }

    USER_UPDATE_RESPONSE = {
      "user" =>
        {
          "id" => "user id (null if failed)",
          "message" => "success or fail message"
        }
    }

    USER_UPDATE_RESPONSE_EXAMPLE = {
      "user"=>
        {
          "id"=> 56,
          "message"=> "User has been updated successfully"
        }
    }

    NOTIFIERS_EXAMPLE = {
      "notifiers" => {
        "can_notify" => true,
        "new_comment_commit_owner" => true,
        "new_comment_commit_repo_owner" => false,
        "new_comment_commit_commentor" => true,
        "new_comment"=> true,
        "new_comment_reply" => true,
        "new_issue" => true,
        "issue_assign" => true,
        "new_build" => true,
        "new_associated_build" => false
      }
    }

    USER_UPDATE_NOTIFIERS_REQUEST = NOTIFIERS_EXAMPLE
    USER_UPDATE_NOTIFIERS_RESPONSE = {
      "user" =>
        {
          "id" => "user id (null if failed)",
          "message" => "success or fail message"
        }
    }

    USER_UPDATE_NOTIFIERS_RESPONSE_EXAMPLE = {
      "user"=>
        {
          "id"=> 56,
          "message"=> "User notification settings have been updated successfully"
        }
    }

    USER_NOTIFIERS_RESPONSE = {
      "user" => {
        "id" => "user id",
        "notifiers" => {
          "can_notify" => "notifications by email",
          "new_comment_commit_owner" => "notify about comments to my commit",
          "new_comment_commit_repo_owner" => "notify about comments to my repository commits",
          "new_comment_commit_commentor" => "notify about comments after my commit",
          "new_comment"=> "new task comment notifications",
          "new_comment_reply" => "new reply of comment notifications",
          "new_issue" => "new task notifications",
          "issue_assign" => "new task assignment notifications",
          "new_build" => "notify about my build tasks",
          "new_associated_build" => "notify about associated with me build tasks"
        }
      },
      "url" => "user notification settings path"
    }

    USER_NOTIFIERS_RESPONSE_EXAMPLE = {
      "user" => {
        "id" => 5,
      }.merge(NOTIFIERS_EXAMPLE),
      "url" => "/api/v1/user/notifiers.json"
    }

    GROUP_PARAMS = {
      "id" => "group id",
      "uname" => "group uname",
      "own_projects_count" => "count of own projects",
      "created_at" => "group created at",
      "updated_at" => "group updated_at",
      "description" => "group description",
      "owner" => {
        "id" => "owner id",
        "name" => "owner name",
        "type" => "owner type",
        "url" => "path to owner data"
      },
      "avatar_url" => "avatar url",
      "html_url"=> "html group path",
      "url" => "api group path",
    }

    GROUP_PARAMS_EXAMPLE = {
      "id" => 1,
      "uname" => "rosa",
      "own_projects_count" => 5,
      "created_at" => 1349357795,
      "updated_at" => 1349358084,
      "description" => "public group",
      "owner" => {
        "id" => 5,
        "name" => "Timothy Bobrov1",
        "type" => "User",
        "url" => "/api/v1/users/5.json"
      },
      "avatar_url" => "avatar url",
      "html_url"=> "/rosa",
      "url" => "/api/v1/groups/1.json"
    }

    GROUP_LIST_RESPONSE = {
      "groups" => [GROUP_PARAMS],
      "url" => "path to groups data"
    }

    GROUP_LIST_RESPONSE_EXAMPLE = {
      "groups" => [GROUP_PARAMS_EXAMPLE],
      "url" => "/api/v1/groups.json"
    }

    GROUP_DATA_RESPONSE = {
      "group" => GROUP_PARAMS
    }

    GROUP_DATA_RESPONSE_EXAMPLE = {
      "group" => GROUP_PARAMS_EXAMPLE
    }

    GROUP_UPDATE_REQUEST = {
      "group" => {
        "description" => "group description"
      }
    }

    GROUP_UPDATE_RESPONSE = {
      "group" => {
        "id" => "group id (null if failed)",
        "message" => "success or fail message"
      }
    }

    GROUP_UPDATE_RESPONSE_EXAMPLE = {
      "group"=> {
        "id"=> 56,
        "message"=> "Group has been updated successfully"
      }
    }

    GROUP_CREATE_REQUEST = {
      "group" => {
        "uname" => "group uname",
        "description" => "group description"
      }
    }
    GROUP_CREATE_RESPONSE = GROUP_UPDATE_RESPONSE
    GROUP_CREATE_RESPONSE_EXAMPLE = {
      "group"=> {
        "id"=> 56,
        "message"=> "Group has been created successfully"
      }
    }

    GROUP_DESTROY_RESPONSE = GROUP_UPDATE_RESPONSE
    GROUP_DESTROY_RESPONSE_EXAMPLE = {
      "group"=> {
        "id"=> 56,
        "message"=> "Group has been destroyed successfully"
      }
    }

    GROUP_MEMBERS_RESPONSE = {
      "group" => {
        "id" => "group id",
        "members" => [
          {
            "id" => "member id",
            "type" => "only User may be member of group",
            "url" => "user path"
          }
        ]
      },
      "url" => "members path"
    }

    GROUP_MEMBERS_RESPONSE_EXAMPLE = {
      "group" => {
        "id" => 77,
        "members" => [
          {
            "id" => 31,
            "type" => "User",
            "url" => "/api/v1/users/31.json"
          },
          {
            "id" => 22,
            "type" => "User",
            "url" => "/api/v1/users/22.json"
          }
        ]
      },
      "url" => "/api/v1/groups/77/members.json"
    }

    GROUP_ADD_MEMBER_REQUEST = {
      "member_id" => 34,
      "role" => "admin"
    }

    GROUP_ADD_MEMBER_RESPONSE = GROUP_UPDATE_RESPONSE
    GROUP_ADD_MEMBER_RESPONSE_EXAMPLE = {
      "group"=>
        {
          "id"=> 56,
          "message"=> "User '34' has been added to group successfully"
        }
    }

    GROUP_REMOVE_MEMBER_REQUEST = {
      "member_id" => 34
    }

    GROUP_REMOVE_MEMBER_RESPONSE = GROUP_UPDATE_RESPONSE

    GROUP_REMOVE_MEMBER_RESPONSE_EXAMPLE = {
      "group"=>
        {
          "id"=> 56,
          "message"=> "User '32' has been removed from group successfully"
        }
    }

    GROUP_UPDATE_MEMBER_REQUEST = GROUP_ADD_MEMBER_REQUEST
    GROUP_UPDATE_MEMBER_RESPONSE = GROUP_UPDATE_RESPONSE
    GROUP_UPDATE_MEMBER_RESPONSE_EXAMPLE = {
      "group"=>
        {
          "id"=> 56,
          "message"=> "Role for user '34' has been updated in group successfully"
        }
    }

    ADVISORY_PARAMS = {
      "id" => "advisory id",
      "description" => "advisory description",
      "platforms" => [
        {
          "id" => "platform id",
          "released" => "platform released",
          "url" => "path to platform data"
        }
      ],
      "projects" => [PROJECT_PARTIAL],
      "url" => "path to advisory data"
    }

    ADVISORY_PARAMS_EXAMPLE = {
      "id" => "ROSA-SA-2012:0188",
      "description" => "hello world",
      "platforms" => [
        {
          "id" => 22,
          "released" => true,
          "url" => "/api/v1/platforms/22.json"
        }
      ],
      "projects" => [PROJECT_PARTIAL_EXAMPLE],
      "url" => "/api/v1/advisories/ROSA-SA-2012:0188.json"
    }

    ADVISORY_LIST_RESPONSE = {
      "advisories" => [ADVISORY_PARAMS],
      "url" => "path to advisories data"
    }

    ADVISORY_LIST_RESPONSE_EXAMPLE = {
      "advisories" => [ADVISORY_PARAMS_EXAMPLE],
      "url" => "/api/v1/advisories.json"
    }

    ADVISORY_DATA_RESPONSE = {
      "advisories" => ADVISORY_PARAMS.merge({
        "created_at" => "advisory created at",
        "updated_at" => "advisory updated_at",
        "update_type" => "update type of advisory (security or bugfix)",
        "references" => ["advisory reference"],
        "build_lists" => [
          {
            "id" => "build_list id",
            "url" => "path to build_list data"
          }
        ],
        "affected_in" => [
          {
            "id" => "platform id",
            "url" => "path to platform data",
            "projects" => [
              {
                "id" => "project id",
                "url" => "path to project data",
                "srpm" => "SRPM package",
                "rpm" => ["RPM package"]
              }
            ]
          }
        ]
      })
    }

    ADVISORY_DATA_RESPONSE_EXAMPLE = {
      "advisory" => ADVISORY_PARAMS_EXAMPLE.merge({
        "created_at" => 1348168705,
        "updated_at" => 1348168905,
        "update_type" => "security",
        "references" => [
          "http://www.test.net/test-0-97-5/",
          "http://www.test2.com/test2-0-97-5/"
        ],
        "build_lists" => [
          {
            "id" => 739683,
            "url" => "/api/v1/build_lists/739683.json"
          }
        ],
        "affected_in" => [
          {
            "id" => 22,
            "url" => "/api/v1/platforms/22.json",
            "projects" => [
              {
                "id" => 4661,
                "url" => "/api/v1/projects/4661.json",
                "srpm" => "mozilla-thunderbird-l10n-10.0.7-0.1.src.rpm",
                "rpm" => ["mozilla-thunderbird-zh_TW-10.0.7-0.1-rosa.lts2012.0.noarch.rpm", "mozilla-thunderbird-zh_CN-10.0.7-0.1-rosa.lts2012.0.noarch.rpm"]
              }
            ]
          }
        ]
      })
    }

    ADVISORY_CREATE_REQUEST = {
      "advisory" => {
        "description" => "Updated to new version",
        "references" => [
          "www.test.net/test-0-97-5/",
          "http://www.test2.com/test2-0-97-5/"
        ]
      },
      "build_list_id" => 15
    }
    ADVISORY_CREATE_RESPONSE = {
      "advisory" => {
        "id" => "advisory id (null if failed)",
        "message" => "success or fail message"
      }
    }
    ADVISORY_CREATE_RESPONSE_EXAMPLE = {
      "advisory"=> {
        "id"=> 56,
        "message"=> "Advisory has been created successfully"
      }
    }

    ADVISORY_ATTACH_REQUEST = {
      "build_list_id" => 15
    }
    ADVISORY_ATTACH_RESPONSE = ADVISORY_CREATE_RESPONSE
    ADVISORY_ATTACH_RESPONSE_EXAMPLE = {
      "advisory"=> {
        "id"=> 56,
        "message"=> "Build list '15' has been attached to advisory successfully"
      }
    }

    FILE_STORE_CREATE_RESPONSE = {
      "sha1_hash" => "File SHA1"
    }
    FILE_STORE_CREATE_RESPONSE_EXAMPLE = {
      "sha1_hash" => "3a93e5553490e39b4cd50269d51ad8438b7e20b8"
    }

    FILE_STORE_FIND_RESPONSE = [
      {
        "sha1_hash" => "File SHA1",
        "file_name" => "File name",
        "user" => {
          "id" => "User id in ABF",
          "uname" => "User uname in ABF"
        }
      }
    ]

    FILE_STORE_FIND_RESPONSE_EXAMPLE = [
      {
        "sha1_hash" => "3a93e5553490e39b4cd50269d51ad8438b7e20b8",
        "file_name" => "kernel.tar.gz2",
        "user" => {
          "id" => "1",
          "uname" => "ivan_aivazovsky"
        }
      }
    ]

    SEARCH_REQUEST = {
      "query" => "search term",
      "type" => "type of search results"
    }

    SEARCH_REQUEST_EXAMPLE = {
      "query" => "test",
      "type" => "users"
    }

    SEARCH_RESPONSE = {
      "results" => [
        "users" => [ USER_PARTIAL ],
        "groups" => [
          {
            "id" => "group id",
            "uname" => "group uname",
            "url" => "api group path"
          }
        ],
        "projects" => [PROJECT_PARTIAL],
        "platforms" => [PLATFORM_PARTIAL]
      ],
      "url" => "path to search request"
    }

    SEARCH_RESPONSE_EXAMPLE = {
      "results" => {
        "users" => [ USER_PARTIAL_EXAMPLE ],
        "groups" => [
          {
            "id" => 1,
            "uname" => "rosa",
            "url" => "/api/v1/groups/1.json"
          }
        ],
        "projects" => [PROJECT_PARTIAL_EXAMPLE],
        "platforms" => [PLATFORM_PARTIAL_EXAMPLE]
      },
      "url" => "/api/v1/search.json"
    }


    MAINTAINER_LIST_RESPONSE = {
      'maintainers' => [
        {
          'project' => PROJECT_PARTIAL,
          'package' => PACKAGE_PARTIAL,
          'maintainer' => USER_PARTIAL.merge('email' => 'user email')
        }
      ]
    }

    MAINTAINER_LIST_RESPONSE_EXAMPLE = {
      'maintainers' => [
        {
          'project' => PROJECT_PARTIAL_EXAMPLE,
          'package' => PACKAGE_PARTIAL_EXAMPLE,
          'maintainer' => USER_PARTIAL_EXAMPLE.merge('email' => 'ivan.aivazovsky@email.ru ')
        }
      ]
    }

    PRODUCT_DATA_RESPONSE = {
      'product' => PRODUCT_PARTIAL.merge({
        'platform' => PLATFORM_PARTIAL,
        'project' => PROJECT_PARTIAL,
        'created_at' => 'created at date and time',
        'updated_at' => 'updated at date and time'
      })
    }

    PRODUCT_DATA_RESPONSE_EXAMPLE = {
      'product' => PRODUCT_PARTIAL_EXAMPLE.merge({
        'platform' => PLATFORM_PARTIAL_EXAMPLE,
        'project' => PROJECT_PARTIAL_EXAMPLE,
        'created_at' => '1348168705',
        'updated_at' => '1348168705'
      })
    }

    PRODUCT_CREATE_REQUEST = {
      "product" => {
        'platform_id' => 15,
        'project_id'  => 100,
        'name' => 'rosa2012lts_ee',
        'description' => 'Extended Edition ROSA 2012 Marathon with non-free and restricted',
        'main_script' => 'MATRIX',
        'params' => 'lst=libs externalarch=\"x86_64\" PRODUCTNAME=ROSA.201...',
        'time_living' => 60,
        'autostart_status' => 0
      }
    }

    PRODUCT_CREATE_RESPONSE = {
      "product" => {
        "id"      => "product id (null if failed)",
        "message" => "success or fail message"
      }
    }

    PRODUCT_CREATE_RESPONSE_EXAMPLE = {
      "product" => {
        "id" => 12,
        "message" => "Product has been created successfully"
      }
    }

    PRODUCT_UPDATE_REQUEST = {
      'product' =>
        PRODUCT_CREATE_REQUEST['product'].select {|key, value| key != 'platform_id'}
    }

    PRODUCT_UPDATE_RESPONSE = PRODUCT_CREATE_RESPONSE

    PRODUCT_UPDATE_RESPONSE_EXAMPLE = {
      "product" => {
        "id" => 12,
        "message" => "Product has been updated successfully"
      }
    }

    PRODUCT_DESTROY_RESPONSE = PRODUCT_UPDATE_RESPONSE
    PRODUCT_DESTROY_RESPONSE_EXAMPLE = {
      "product"=> {
        "id"=> 12,
        "message"=> "Product has been destroyed successfully"
      }
    }

    PRODUCT_BUILD_LIST_IND = {
      'id' => 'resource id',
      'status' => 'status code',
      'notified_at' => 'updated at date and time',
      'time_living' => 'Max time for building (in minutes)',
      'url' => 'product build list page',
    }

    PRODUCT_BUILD_LIST_IND_EXAMPLE = {
      'id' => '1',
      'status' => '0',
      'notified_at' => '1348168705',
      'time_living' => '60',
      'url' => '/api/v1/product_build_lists/26.json',
    }

    PRODUCT_BUILD_LIST_PARTIAL = PRODUCT_BUILD_LIST_IND.merge({
      'product' => PRODUCT_PARTIAL,
      'project' => PROJECT_PARTIAL,
      'arch' => {
        'id' => 'build architecture id',
        'name' => 'build architecture name'
      },
     'main_script' => 'main script',
      'params' => 'params for running script',
      'commit_hash' => 'commit hash to build',
      'results'  => [{
          'file_name' => 'file name',
          'size'      => 'file size',
          'url'       => 'file url'
      }],
    })

    PRODUCT_BUILD_LIST_PARTIAL_EXAMPLE = PRODUCT_BUILD_LIST_IND_EXAMPLE.merge({
      'product' => PRODUCT_PARTIAL_EXAMPLE,
      'project' => PROJECT_PARTIAL_EXAMPLE,
      'arch' => {
        'id' => '1',
        'name' => 'x84_64'
      },
     'main_script' => 'MATRIX',
     'params' => 'lst=libs externalarch=\"x86_64\" PRODUCTNAME=ROSA.201...',
     'commit_hash' => '751b0cad9cd1467e735d8c3334ea3cf988995fab',
      'results'  => [{
          'file_name' => 'abfworker::rpm-worker-859694.log',
          'size'      => '214310',
          'url'       => 'http://file-store.rosalinux.ru/api/v1/file_stores/3a93e5553490e39b4cd50269d51ad8438b7e20b8'},
          {
          'file_name' => 'archives.tar.gz',
          'size'      => '2014310',
          'url'       => 'http://file-store.rosalinux.ru/api/v1/file_stores/c28a1e69fe8543afd6977480c225c5243fdce2d5'}
      ],
    })

    PRODUCT_BUILD_LIST_DATA_RESPONSE = {
      'product_build_list' => PRODUCT_BUILD_LIST_PARTIAL.merge({
        'created_at' => 'created at date and time',
        'updated_at' => 'updated at date and time',
        'not_delete' => 'block deleting after finish lifetime',
        'autostarted' => 'true - if build has been autostarted'
      })
    }

    PRODUCT_BUILD_LIST_DATA_RESPONSE_EXAMPLE = {
      'product_build_list' => PRODUCT_BUILD_LIST_PARTIAL_EXAMPLE.merge({
        'created_at' => '1348168705',
        'updated_at' => '1348168705',
        'not_delete' => false,
        'autostarted' => false
      })
    }

    PRODUCT_BUILD_LIST_CREATE_REQUEST = {
      "product_build_list" => {
        'product_id' => '1',
        'project_id'  => '100',
        'commit_hash' => '751b0cad9cd1467e735d8c3334ea3cf988995fab',
        'arch_id' => '1',
        'main_script' => 'MATRIX',
        'params' => 'lst=libs externalarch=\"x86_64\" PRODUCTNAME=ROSA.201...',
        'time_living' => '60',
      }
    }

    PRODUCT_BUILD_LIST_CREATE_RESPONSE = {
      "product_build_list" => {
        "id"      => "product build list id (null if failed)",
        "message" => "success or fail message"
      }
    }

    PRODUCT_BUILD_LIST_CREATE_RESPONSE_EXAMPLE = {
      "product_build_list" => {
        "id" => 12,
        "message" => "Product build list has been created successfully"
      }
    }

    PRODUCT_BUILD_LIST_UPDATE_REQUEST = {
      "product_build_list" => {
        'not_delete' => true
      }
    }

    PRODUCT_BUILD_LIST_UPDATE_RESPONSE = PRODUCT_BUILD_LIST_CREATE_RESPONSE
    PRODUCT_BUILD_LIST_UPDATE_RESPONSE_EXAMPLE = {
      "product_build_list"=> {
        "id"=> 12,
        "message"=> "Product build list has been updated successfully"
      }
    }

    PRODUCT_BUILD_LIST_DESTROY_RESPONSE = PRODUCT_BUILD_LIST_CREATE_RESPONSE
    PRODUCT_BUILD_LIST_DESTROY_RESPONSE_EXAMPLE = {
      "product_build_list"=> {
        "id"=> 12,
        "message"=> "Product build list has been destroyed successfully"
      }
    }

    PRODUCT_BUILD_LIST_CANCEL_RESPONSE = PRODUCT_BUILD_LIST_CREATE_RESPONSE
    PRODUCT_BUILD_LIST_CANCEL_RESPONSE_EXAMPLE = {
      "product_build_list"=> {
        "id"=> 12,
        "message"=> "Product build list has been canceled successfully"
      }
    }

    PRODUCT_BUILD_LIST_RESPONSE = {
      'product_build_lists' => [PRODUCT_BUILD_LIST_IND],
      'url' => 'current url for product build lists page',
    }

    PRODUCT_BUILD_LIST_RESPONSE_EXAMPLE = {
      'product_build_lists' => [PRODUCT_BUILD_LIST_IND_EXAMPLE],
      'url' => '/api/v1/product_build_lists.json',
    }

    LABEL_PARTIAL = {
      'name' => 'name',
      'color' => 'color'
    }

    LABEL_PARTIAL_EXAMPLE = {
      'name' => 'Feature',
      'color' => '02e10c'
    }

    LABEL_DATA_RESPONSE = LABEL_PARTIAL
    LABEL_DATA_RESPONSE_EXAMPLE = LABEL_PARTIAL_EXAMPLE

    LABELS_LIST_RESPONSE = {
      'labels' => [LABEL_DATA_RESPONSE]
    }

    LABELS_LIST_RESPONSE_EXAMPLE = {
      'labels' => [LABEL_DATA_RESPONSE_EXAMPLE]
    }

    ISSUE_PARTIAL = {
      'number' => 'serial number',
      'title' => 'title',
      'status' => 'issue status',
      'labels' => [LABEL_DATA_RESPONSE],
      'assignee' => USER_PARTIAL,
      'url' => 'url to issue data page'
    }

    ISSUE_PARAMS = ISSUE_PARTIAL.merge({
      'body' => 'body',
      'owner' => USER_PARTIAL,
      'closed_at' => 'closed at date and time',
      'closed_by' => USER_PARTIAL,
      'created_at' => 'created at date and time',
      'updated_at' => 'updated at date and time'
    })

    ISSUES_LIST_RESPONSE = {
      'issues' => [ISSUE_PARAMS],
      'url' => 'path to issues data'
    }

    ISSUE_PARTIAL_EXAMPLE = {
      'number' => '11',
      'title' => 'new feature',
      'status' => 'open',
      'labels' => [LABEL_DATA_RESPONSE_EXAMPLE],
      'assignee' => USER_PARTIAL_EXAMPLE,
      'url' => '/api/v1/projects/3/issues/11.json'
    }

    ISSUE_PARAMS_EXAMPLE = ISSUE_PARTIAL_EXAMPLE.merge({
      'body' => 'new cool feature for us',
      'owner' => USER_PARTIAL_EXAMPLE,
      'closed_at' => '1348170705',
      'closed_by' => USER_PARTIAL_EXAMPLE,
      'created_at' => '1348170705',
      'updated_at' => '1348168705'
    })

    ISSUES_LIST_RESPONSE_EXAMPLE = {
      'issues' => [ISSUE_PARAMS_EXAMPLE],
      'url' => '/api/v1/projects/3/issues.json'
    }

    ISSUE_DATA_RESPONSE = {
      'issue'=> ISSUE_PARAMS
    }

    ISSUE_DATA_RESPONSE_EXAMPLE = {
      'issue' => ISSUE_PARAMS_EXAMPLE
    }

    ISSUE_UPDATE_EXAMPLE = {
      'title' => 'fix security bug',
      'body' => 'fixed at 123456',
      'status' => 'closed',
      'assignee_id' => 15,
      'labels' => ['Security', 'Bug']
    }

    ISSUE_UPDATE_REQUEST = {
      'issue' => ISSUE_UPDATE_EXAMPLE
    }

    ISSUE_UPDATE_RESPONSE = {
      'issue' => {
        'number' => 'issue number (null if failed)',
        'message' => 'success or fail message'
      }
    }

    ISSUE_UPDATE_RESPONSE_EXAMPLE = {
      'issue' => {
        'number' => 12,
        'message' => 'Issue has been updated successfully'
      }
    }

    ISSUE_CREATE_REQUEST = {
      'issue' => ISSUE_UPDATE_EXAMPLE
    }
    ISSUE_CREATE_RESPONSE = ISSUE_UPDATE_RESPONSE
    ISSUE_CREATE_RESPONSE_EXAMPLE = {
      'issue' => {
        'number' => 12,
        'message' => 'Issue has been created successfully'
      }
    }

    TO_REF_PARTIAL = {
      'ref' => 'reference',
      'sha' => 'sha',
      'project' => PROJECT_PARTIAL
    }

    TO_REF_PARTIAL_EXAMPLE = {
      'ref' => 'update-version',
      'sha' => '3d1468bbb339c8b59234a5bbc35dedf3d89c2043',
      'project' => PROJECT_PARTIAL_EXAMPLE
    }

    FROM_REF_PARTIAL = {
      'ref' => 'reference',
      'sha' => 'sha',
      'project' => PROJECT_PARTIAL
    }

    FROM_REF_PARTIAL_EXAMPLE = {
      'ref' => 'update-rails',
      'sha' => '3d1468bbb339c8b59234a5bbc35dedf3d89c2043',
      'project' => PROJECT_PARTIAL_EXAMPLE
    }

    PULL_REQUEST_PARTIAL = {
      'number' => 'serial number',
      'title' => 'title',
      'to_ref' => TO_REF_PARTIAL,
      'from_ref' => FROM_REF_PARTIAL,
      'status' => 'pull request status',
      'owner' => USER_PARTIAL,
      'assignee' => USER_PARTIAL,
      'merged_at' => 'merged at date and time',
      'mergeable' => 'can be automatically merged',
      'url' => 'url to pull request data page'
    }

    PULL_REQUEST_PARAMS = PULL_REQUEST_PARTIAL.merge({
      'body' => 'body',
      'closed_at' => 'closed at date and time',
      'closed_by' => USER_PARTIAL,
      'created_at' => 'created at date and time',
      'updated_at' => 'updated at date and time',
      'merged_by' => USER_PARTIAL
    })

    PULL_REQUESTS_LIST_RESPONSE = {
      'pull_requests' => [PULL_REQUEST_PARTIAL],
      'url' => 'path to pull request data'
    }

    PULL_REQUEST_PARTIAL_EXAMPLE = {
      'number' => '11',
      'title' => 'new feature',
      'to_ref' => TO_REF_PARTIAL_EXAMPLE,
      'from_ref' => FROM_REF_PARTIAL_EXAMPLE,
      'status' => 'open',
      'owner' => USER_PARTIAL_EXAMPLE,
      'assignee' => USER_PARTIAL_EXAMPLE,
      'merged_at' => '1348170705',
      'mergeable' => 'true',
      'url' => '/api/v1/projects/3/pull_requests/11.json'
    }

    PULL_REQUEST_PARAMS_EXAMPLE = PULL_REQUEST_PARTIAL_EXAMPLE.merge({
      'body' => 'new cool feature for us',
      'closed_at' => '1348170705',
      'closed_by' => USER_PARTIAL_EXAMPLE,
      'created_at' => '1348168705',
      'updated_at' => '1348170705',
      'merged_by' => USER_PARTIAL_EXAMPLE
    })

    PULL_REQUESTS_LIST_RESPONSE_EXAMPLE = {
      'pull_requests' => [PULL_REQUEST_PARTIAL_EXAMPLE],
      'url' => '/api/v1/projects/3/pull_requests.json'
    }

    PULL_REQUEST_DATA_RESPONSE = {
      'pull_request'=> PULL_REQUEST_PARAMS
    }

    PULL_REQUEST_DATA_RESPONSE_EXAMPLE = {
      'pull_request' => PULL_REQUEST_PARAMS_EXAMPLE
    }

    PULL_REQUEST_UPDATE_EXAMPLE = {
      'title' => 'fix security bug',
      'body' => 'fixed at 123456',
      'status' => 'closed',
      'assignee_id' => 15
    }

    PULL_REQUEST_UPDATE_REQUEST = {
      'pull_request' => PULL_REQUEST_UPDATE_EXAMPLE
    }

    PULL_REQUEST_UPDATE_RESPONSE = {
      'pull_request' => {
        'number' => 'pull request number (null if failed)',
        'message' => 'success or fail message'
      }
    }

    PULL_REQUEST_UPDATE_RESPONSE_EXAMPLE = {
      'pull_request' => {
        'number' => 12,
        'message' => 'Pull request has been updated successfully'
      }
    }

    PULL_REQUEST_CREATE_REQUEST = {
      'pull_request' => {
        'title' => 'fix security bug',
        'body' => 'fixed at 123456',
        'assignee_id' => 15,
        'to_ref' => 'master',
        'from_project_id' => 93862,
        'from_ref' => 'new_branch'
      }
    }
    PULL_REQUEST_CREATE_RESPONSE = PULL_REQUEST_UPDATE_RESPONSE
    PULL_REQUEST_CREATE_RESPONSE_EXAMPLE = {
      'pull_request' => {
        'number' => 12,
        'message' => 'Pull request has been created successfully'
      }
    }

    COMMIT_PARTIAL = {
      'sha' => 'commit sha',
      'https_url' => 'commit url',
      'author' => {
        'name' => 'author name',
        'email' => 'author email',
        'date' => 'authored date'
      },
      'committer' => {
        'name' => 'committer name',
        'email' => 'committer email',
        'date' => 'committed date'
      },
      'message' => 'Fix all the bugs',
      'tree' => {
        'sha' => 'commit sha',
        'https_url' => 'tree url'
      },
      'parents' => [{
        'sha' => 'commit sha',
        'https_url' => 'tree url'
      }]
    }

    COMMIT_PARTIAL_EXAMPLE = {
      'sha' => '4c2553a5a339c8b59234a5bbc35dedf3d89c2043',
      'https_url' => 'https://abf.rosalinux.ru/abf/rosa-build/commit/4c2553a5a339c8b59234a5bbc35dedf3d89c2043',
      'author' => {
        'name' => 'abf',
        'email' => 'abf@test.ru',
        'date' => '1348168705'
      },
      'committer' => {
        'name' => 'abf',
        'email' => 'abf@test.ru',
        'date' => '1348168705'
      },
      'message' => 'Fix all the bugs',
      'tree' => {
        'sha' => '4c2553a5a339c8b59234a5bbc35dedf3d89c2043',
        'https_url' => 'https://abf.rosalinux.ru/abf/rosa-build/tree/4c2553a5a339c8b59234a5bbc35dedf3d89c2043'
      },
      'parents' => [{
        'sha' => '20056fbc319722cc64cf7e718b22607693e7f0b0',
        'https_url' => 'https://abf.rosalinux.ru/abf/rosa-build/commit/20056fbc319722cc64cf7e718b22607693e7f0b0'
      }]
    }
    LIST_COMMITS_PULL_REQUEST_DATA_RESPONSE = {
      'commits' => [COMMIT_PARTIAL]
    }
    LIST_COMMITS_PULL_REQUEST_DATA_RESPONSE_EXAMPLE = {
      'commits' => [COMMIT_PARTIAL_EXAMPLE]
    }

    LIST_PULL_REQUESTS_FILES_DATA_RESPONSE = {
      'files' => [{
        'sha' => 'sha',
        'filename' => 'file name',
        'status' => 'file status',
        'additions' => 'additional lines count',
        'deletions' => 'deletions lines count',
        'changes' => 'total lines changes',
        'blob_https_url' => 'blob url',
        'raw_https_url' => 'raw file url'
      }]
    }
    LIST_PULL_REQUESTS_FILES_DATA_RESPONSE_EXAMPLE = {
      'files' => [{
        'sha' => '473cca87b339c8b59234a5bbc35dedf3d89c2043',
        'filename' => 'test.log',
        'status' => 'added',
        'additions' => '42',
        'deletions' => '24',
        'changes' => '66',
        'blob_https_url' => 'https://abf.rosalinux.ru/abf/rosa-build/blob/master/Gemfile',
        'raw_https_url' => 'https://abf.rosalinux.ru/abf/rosa-build/raw/master/Gemfile'
      }]
    }

    PULL_REQUEST_MERGE_REQUEST = {
      'pull_request' => {
        'commit_message' => 'commit message'
      }
    }
    PULL_REQUEST_MERGE_REQUEST_EXAMPLE = {
      'pull_request' => {
        'commit_message' => 'Fix a security bug'
      }
    }
    PULL_REQUEST_MERGE_RESPONSE = PULL_REQUEST_UPDATE_RESPONSE
    PULL_REQUEST_MERGE_RESPONSE_EXAMPLE = {
      'pull_request' => {
        'number' => 12,
        'message' => 'Pull request has been merged successfully'
      }
    }
  end
end

include GitHub::Resources::Helpers
