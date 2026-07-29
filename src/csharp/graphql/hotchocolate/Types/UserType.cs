namespace GraphqlHotChocolate.Types;

public class User
{
    public int Id { get; set; }
    public string Email { get; set; } = "";
    public string FirstName { get; set; } = "";
    public string LastName { get; set; } = "";
    public int Age { get; set; }
    public string CreatedAt { get; set; } = "";
}

public class UserType : ObjectType<User>
{
    protected override void Configure(IObjectTypeDescriptor<User> descriptor)
    {
        descriptor.Name("User");
        descriptor.Field(u => u.Id).Type<NonNullType<IntType>>();
        descriptor.Field(u => u.Email).Type<NonNullType<StringType>>();
        descriptor.Field(u => u.FirstName).Type<NonNullType<StringType>>();
        descriptor.Field(u => u.LastName).Type<NonNullType<StringType>>();
        descriptor.Field(u => u.Age).Type<NonNullType<IntType>>();
        descriptor.Field(u => u.CreatedAt).Type<NonNullType<StringType>>();
    }
}
