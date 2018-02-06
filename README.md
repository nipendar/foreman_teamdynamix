# foreman_teamdynamix
A Foreman Plugin for TeamDynamix. It manages a host lifecycle as a corresponding Asset in TeamDynamix.

## Configuration
[:api][:create] or [:delete]
* All attributes are passed as is to the TeamDynamix API while creating or deleting a TeamDynamix Asset.
* An asset gets created or deleted with the Foreman Host create or delete lifecycle event.

[:api][:create][:Attributes]
* To configure any [Custom Attributes](https://api.teamdynamix.com/TDWebApi/Home/type/TeamDynamix.Api.CustomAttributes.CustomAttribute) for the asset.
* It must contain expected value for 'id' and 'value' fields.
* rest of the fields are optional, check the Custom Attribute's definition for what other fields are updatable.
* String interpolation is suppored for custom attribute's value.

[:fields]
* A link to the asset in Teamdynamix is displayed by default, as first field labelled as URI
* Nested attributes can be configured as mentioned in example configuration below.
* If an attribute or nested attribute does not exist or is not found, it would simply not be displayed.

```
:teamdynamix:
  :api:
    :url: 'td_api_url'
    :id: 'id'
    :username: 'username'
    :password: 'password'
    :create:
      :StatusID: integer_id
      :attribute_name: string
      :Attributes:
      - name: custom attribute name
        id: integer_id
        value: integer or string value
      - name: custom attribute with dynamic value
        id: integer_id
        value: "lorem ipsum #{host.host_attribute_name}"
    :delete
      :StatusID: integer_id
  :title: 'custom title for Team Dynamix Tab'
  :fields:
    Asset ID: ID
    Owner: OwningCustomerName
    Parent Asset: ParentID
    mu.ci.Description: Attributes.'mu.ci.Description'
    Ticket Routing Details: Attributes.'Ticket Routing Details'
    mu.ci.Lifecycle Status: Attributes.mu.ci.Lifecycle Status
    Not an Attribute: Not an Attribute.none
    non-existent nested attribute: Attributes.does not exist
```

## Add additional host attirbute
rake db:migrate

## Development
gem install foreman_teamdynamix --dev
