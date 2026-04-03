package fixture

data class User(val name: String, val age: Int) {
    fun greet(): String = "Hello, $name"
}

fun main() {
    val user = User("MP", 30)
    val message = user.greet()
    println(message)
}
