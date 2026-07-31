using GraphQL.Types;

namespace GraphqlDotnet.Types;

public class User
{
    public int Id { get; set; }
    public string Email { get; set; } = "";
    public string FirstName { get; set; } = "";
    public string LastName { get; set; } = "";
    public int Age { get; set; }
    public string CreatedAt { get; set; } = "";
}

public class UserType : ObjectGraphType<User>
{
    public UserType()
    {
        Name = "User";
        Field(u => u.Id).Type(new NonNullGraphType<IntGraphType>());
        Field(u => u.Email).Type(new NonNullGraphType<StringGraphType>());
        Field(u => u.FirstName).Type(new NonNullGraphType<StringGraphType>());
        Field(u => u.LastName).Type(new NonNullGraphType<StringGraphType>());
        Field(u => u.Age).Type(new NonNullGraphType<IntGraphType>());
        Field(u => u.CreatedAt).Type(new NonNullGraphType<StringGraphType>());
    }
}
