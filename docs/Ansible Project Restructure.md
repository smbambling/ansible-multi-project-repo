# Ansible Multi-Project Directory Structure

Isolation with minimal duplication

## Benefits

* Helps to simplify the understanding of project setup/configuration
* Exhibits the use of multiple Playbooks with a project
  * Provisioning
  * Configuration
  * Adhoc
* Isolation of project variables
* Limits the potential for variable collision
* Limits the inventory scope per project
* Inventory Flexibility per project
* Additional safeguard against accidental playbook execution
* Helps to limit the need for code duplication across roles/projects
* Assist with repeatable configuration synchronization

## Terminology

**role**: A collection of task, template, handlers and variables
focused on a specific goal.

**external galaxy role**: These are are roles that are fetched from an
external source such as the Ansible Galaxy or VCS repository (GitHub).

**corporate role**: These are roles that are fetch from an internal source
such as a local VCS repository.  These are are often business specific and proprietary.

**wrapper role**: These are joint roles that combine tasks for more then one
application suite.  Often a combination of one or more external
and/or corporate roles.

**project**: A logical collection of Playbooks, roles, inventory, groupi\_vars
and host\_vars for a given corporate function.

* The inclusion of a node in multiple projects inventories should be limited,
as the scope of the projects my overlap and provide undesired configuration.

**site**: Different location often geographically distributed,
such as multiple data centers.

**environment**: Also sometimes called tiers in a software deployment pipeline.
Often consist of development,Integration,SI/QA,Stage,Test,Prod

**domain**: A logical grouping defined by network address space, often further
segregated by sub-domains. Such as foo.dev.example.com, foo.ci.example.dev, foo.qa.example.dev

## Ansible Projects

### Multi-Project Directory Layout

```
README.md
ansible.cfg
requirements.yml
external_galaxy_roles/
corporate_roles/
wrapper_roles/
projects/
  base/
    README.md
    playbooks/
      configure.yml
    inventory/
      hosts.yml
    group_vars/
    host_vars/
  project1/
    README.md
    playbooks/
      provision.yml
      configure.yml
    inventory.yml
    group_vars/
    host_vars/
```

## Inventory Structure

There is not a single way of doing inventories. Grouping each of your nodes into a project allows the inventory structure to be sized to meet the needs of each project on an individual basis.

Thus some projects can have a very simple inventory structure with only a minimal amount of groups/hosts in a single site.  While other project might adopt a multistage environment inventory setup, that can span multiple environments across one or more sites.

### Inventory Structure Considerations

The most important consideration when creating your inventory structure is what
group specific data (group\_vars) your project will need. Some examples are
groups based on the purpose/function (role/project) of the
hosts, geography, datacenter location or environment (if applicable).

The second defining consideration is Playbook execution orchestration.
These are groups used in combination with
[patterns](http://docs.ansible.com/ansible/intro_patterns.html) to
choose which hosts will be targeted during a specific execution run of your Playbooks.

These defining considerations often overlap allowing for a streamline inventory structure.

### Multistage Environment Inventory Structure

One approach when working with multistage environments is to completely
separate each environment into its own inventory structure including separate `group_vars`/`host_vars`.

This approach can be molded to fit your specific projects needs with groups
per site, application or other organizational structure required.

This options requires that cross environment variables be stored in a
common file that is symlink'd within each environment sub structure.

```yaml
projects/
  proj1/
    inventory/
      000_cross_env_vars.yml
      dev/
      qa/
      stage/
      prod/
        group_vars/
          all/
            000_cross_env_vars -> ../../../000_cross_env_vars.yml
            all.yml
          sitea/
            sitea.yml
          siteb/
            siteb.yml
        host_vars/
        hosts.yml
```

Another approach when using multistage environments is to have a single inventory with groups based on environments.

### Simple Inventory

Below is a simple inventory layout, allows control over nodes within a project both via `site` and further sorted by `even`/`odd` nodes that could allow for a rolling update within each site.

```yaml
projects
  <project_name>
    inventory/
      hosts.yml
    group_vars/
    host_vars/
```

```ini
[sitea]
web1.sitea.example.com

[siteb:children]
siteb_odd
siteb_even

[siteb_odd]
web1.siteb.example.com

[siteb_even]
web2.siteb.example.com
```

More complex inventories may be desired or required. To aid in the readability and understanding of larger inventory set the option to have an inventory directory with multiple inventory files.


## Multiple Playbooks

Multiple Playbooks can easily be categorized per project. Providing a single location for all Playbooks associated for a given project.

Examples of Playbooks for a project maybe for for the following actions:
  - Provisioning
  - Setup/Configuration
  - Adhoc Tasks
  - Rolling Updates

Playbooks can even include other playbooks, such as a Playbook that combines both a provisioning and configuration Playbook.  That would both created the necessary container or virtual machine along with applying settings needed for the project ( corporate function )

## Wrapper Roles

Each wrapper role configures a layered technology stack, using multiple internal/external galaxy roles and individual tasks to provide a common functional unit to assist in project deployment.

When a role wraps around another role, it inherits the automation of that role.  The wrapping role can then define attributes to override the default attributes provided by the underlying role.  Instead of copying a role into your project and redefining its variables directly. This helps to maintain modularity and abstract away the complexity of dependencies.  No two roles attempt to automate the same thing.  

Think of this in the term of lego bricks and combining them to build a house. If we know that every house needs to have a wall with a door we can pre-construct that frame using the components of modules,tasks and roles to be used to more quickly and reliable construct a home.

### Examples

A example of a wrapper role could a a `common`/`base` role.  This is one that get applied to a large set if not all of your infrastructure to apply the following standard configurations:

* User account management (Operational Staff)
* **Monitoring Role**, to install a needed application and configure a standard set of system monitoring/metric collection checks
* **DNS Client Role**, to manage systems resolv.conf entries
* **NTP Role**, to manage systems NTP configurations
* **Postfix Role**, to manage a system default mail configuration.

Another example of a wrapper role could be Apache.  This wrapper role could be a combination of the following:

* **Apache Role**, to install/configure the Apache service
* **Logrotate Role**, to manage the rotation, compression,
     removal of log files for the Apache service
* **Monitoring Tasks**, to provide a standard set of Apache application monitoring/metric collection
* **Security Tasks**, to provide any set of standard configurations not handled by the included Apache Role

## Ansible Code Snippets

The use of a common patterns and practices guide along with a directory of snippets will help in maintaining a consistent readable and easy to understand code base across multiple projects.

## Version Control

### Pre-Commit Hooks

To aid in finding and fixing common issues before they are committed for code review, pre-commit hooks can be utilized. This helps to allow reviewers to pay attention to flow of the code without worrying about trivial errors.

Yelp provides a a framework for [pre-commit](http://pre-commit.com) hooks that help to run checks against your local code.

These can be used to run the following tests:

- Ansible-lint
- YAML syntax
- Python jinja2 syntax
- Playbook syntax

### Pre-Recieve Hooks

Similar to pre-commit hooks installed locally in a users development environment, pre-recieve hooks can be put in place to prevent commits to the central VCS repository that could potentially cause failures in a CI environment or fail to run against a host.

## References

https://www.digitalocean.com/community/tutorials/how-to-manage-multistage-environments-with-ansible

https://fale.io/blog/2017/03/01/ansible-inventories/

https://nylas.com/blog/graduating-past-playbooks/
