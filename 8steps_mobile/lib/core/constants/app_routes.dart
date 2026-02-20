class AppRoutes {
  static const onboarding = '/';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const transactions = '/transactions';
  static const categories = '/categories';
  static const accounts = '/accounts';
  static const cards = '/cards';
  static const recurrings = '/recurrings';
  static const financialCalendar = '/financial-calendar';
  static const reports = '/reports';
  static const cardDetailPattern = '/cards/:cardId';
  static const projection = '/projection';

  static String cardDetail(String cardId) => '/cards/$cardId';
}
