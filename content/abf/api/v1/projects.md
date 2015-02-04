---
title: Projects | ABF API
---

# Projects API

* [List projects](#list-projects)
* [Get a single project](#get-a-single-project)
* [Get project id](#get-project-id)
* [Get all references of project](#get-all-references-of-project)
* [Update a single project](#update-a-single-project)
* [Create project](#create-project)
* [Destroy project](#destroy-project)
* [Fork project](#fork-project)
* [Alias project](#alias-project)
* [Members of a single project](#members-of-a-single-project)
* [Add member to a single project](#add-member-to-a-single-project)
* [Remove member from a single project](#remove-member-from-a-single-project)
* [Update member role for a single project](#update-member-role-for-a-single-project)

## List projects

List all projects across all the authenticated user’s projects including owned projects, member projects, and group projects.

    GET /api/v1/projects.json

### Response:

<%= json(:project_list_response) %>

### Example:

<%= json(:project_list_response_example) %>

## Get a single project

    GET /api/v1/projects/:id.json

### Parameters:

id
: _Required_ **Integer** identifier of current project.

### Response:

<%= json(:project_data_response) %>

### Example:

<%= json(:project_data_response_example) %>

## Get project id

    GET /api/v1/projects/get_id.json?name=:project_name&owner=:owner_name

### Parameters:

project_name
: _String_ project name.

owner_name:
: _String_ project owner name.

### Request examples:

    /api/v1/projects/get_id.json?name=rails&owner=warpc

### Response:

<%= json(:project_get_id_response) %>

### Example:

<%= json(:project_get_id_response_example) %>

## Get all references of project

    GET /api/v1/projects/:id/refs_list.json

### Parameters:

id
: _Required_ **Integer** identifier of current project.

### Response:

<%= json(:project_refs_list_response) %>

### Example:

<%= json(:project_refs_list_response_example) %>

## Update a single project

    PUT /api/v1/projects/:id.json

### Parameters:

id
: _Required_ **Integer** identifier of current project.

### Input:

name:
: _Optional_ **String** project name.

description:
: _Optional_ **String** project description.

visibility:
: _Optional_ **String** project visibility (`open`/`hidden`).

is_package:
: _Optional_ **Boolean** `true` if project is package.

default_branch:
: _Optional_ **String** project default branch.

has_issues:
: _Optional_ **Boolean** enable/disable project Issues tracker.

has_wiki:
: _Optional_ **Boolean** enable/disable project wiki.

maintainer_id:
: _Optional_ **Integer** identifier of project maintainer.

<dl>
  <dt>publish_i686_into_x86_64:</dt>
  <dd>
    <em>Optional</em>
    <strong>Boolean</strong>
    enable/disable publishing i686 packages into x86_64 repository (only for rhel).
  </dd>
</dl>

### Request:

<%= json(:project_update_request) %>

### Response:

<%= json(:project_update_response) %>

### Example:

<%= json(:project_update_response_example) %>

## Create project

    POST /api/v1/projects.json

### Input:

name:
: _Required_ **String** project name.

owner_id:
: _Required_ **Integer** identifier of project owner.

owner_type:
: _Required_ **String** type of project owner.

visibility:
: _Required_ **String** project visibility (`open`/`hidden`).

description:
: _Optional_ **String** project description.

is_package:
: _Optional_ **Boolean** `true` if project is package. Default value: `true`.

default_branch:
: _Optional_ **String** project default branch. Default value: `master`.

has_issues:
: _Optional_ **Boolean** enable/disable project Issues tracker. Default value: `true`.

has_wiki:
: _Optional_ **Boolean** enable/disable project wiki. Default value: `false`.

maintainer_id:
: _Optional_ **Integer** identifier of project maintainer. Default value: current user.

publish_i686_into_x86_64:
: _Optional_ **Boolean** enable/disable publishing i686 packages into x86_64 repository (only for rhel).

### Request:

<%= json(:project_create_request) %>

### Response:

<%= json(:project_create_response) %>

### Examples:

<%= json(:project_create_response_example) %>

## Destroy project

    DELETE /api/v1/projects/:id.json

### Parameters:

id
: _Required_ **Integer** identifier of current project.

### Request example:

    /api/v1/projects/54.json

### Response:

<%= json(:project_destroy_response) %>

### Examples:

<%= json(:project_destroy_response_example) %>

## Fork project

    POST /api/v1/projects/:id/fork.json

### Parameters:

id
: _Required_ **Integer** identifier of current project.

fork_name
: _Optional_ **String** name of new project.

### Input:

group_id:
: _Optional_ **Integer** identifier of group which will be project owner. By default (empty request) current user will be project owner.

### Request:

<%= json({"fork_name" => 'new_name'}) %>

&nbsp;

<%= json(:project_fork_request) %>

### Response:

<%= json(:project_fork_response) %>

### Examples:

<%= json(:project_fork_response_example) %>

## Alias project

    POST /api/v1/projects/:id/alias.json

### Parameters:

id
: _Required_ **Integer** identifier of current project.

fork_name
: _Optional_ **String** name of new project.

### Input:

group_id:
: _Optional_ **Integer** identifier of group which will be project owner. By default (empty request) current user will be project owner.

### Request:

<%= json({"fork_name" => 'new_name'}) %>

&nbsp;

<%= json(:project_fork_request) %>

### Response:

<%= json(:project_fork_response) %>

### Examples:

<%= json(:project_fork_response_example) %>

## Members of a single project

    GET /api/v1/projects/:id/members.json

### Parameters:

id
: _Required_ **Integer** identifier of current project.

### Request example:

    /api/v1/projects/53/members.json

### Response:

<%= json(:project_members_response) %>

### Example:

<%= json(:project_members_response_example) %>

## Add member to a single project

    PUT /api/v1/projects/:id/add_member.json

### Parameters:

id
: _Required_ **Integer** identifier of current project.

### Input:

member_id
: _Required_ **Integer** identifier of new member.

type
: _Required_ **String** `Group` or `User` type of new member.

role
: _Required_ **String** role for new member (`reader`/`writer`/`admin`).


### Request:

<%= json(:project_add_member_request) %>

### Response:

<%= json(:project_add_member_response) %>

### Examples:

<%= json(:project_add_member_response_example) %>

&nbsp;

<%= json(:project_add_member_response_example2) %>

## Remove member from a single project

    DELETE /api/v1/projects/:id/remove_member.json

### Parameters:

id
: _Required_ **Integer** identifier of current project.

### Input:

member_id
: _Required_ **Integer** identifier of member.

type
: _Required_ **String** `Group` or `User` type of member.

### Request:

<%= json(:project_remove_member_request) %>

### Response:

<%= json(:project_remove_member_response) %>

### Examples:

<%= json(:project_remove_member_response_example) %>

&nbsp;

<%= json(:project_remove_member_response_example2) %>

## Update member role for a single project

    PUT /api/v1/projects/:id/update_member.json

### Parameters:

id
: _Required_ **Integer** identifier of current project.

### Input:

member_id
: _Required_ **Integer** identifier of member.

type
: _Required_ **String** `Group` or `User` type of member.

role
: _Required_ **String** new role for member (`reader`, `writer`, `admin`).

### Request:

<%= json(:project_update_member_request) %>

### Response:

<%= json(:project_update_member_response) %>

### Examples:

<%= json(:project_update_member_response_example) %>

&nbsp;

<%= json(:project_update_member_response_example2) %>
