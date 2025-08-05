import Foundation

public enum NetworkServiceError: String, Error, CaseIterable {
    case urlError = "A URL inserida é inválida"
    case unauthorized = "Sua sessão expirou.\nEfetue o login novamente."
    case dataError = "Verifique os dados informados."
    case clientError = "Verifique os dados informados e a sua conexão com a internet. Caso o error persista entre em contato com o nosso suporte."
    case serverError = "Parece que estamos passando por manutenção nos servidores.\nTente novamente mais tarde."
    case unknownError = "Um erro inesperado ocorreu.\nEntre em contato com o nosso suporte ou tente novamente mais tarde."
}
