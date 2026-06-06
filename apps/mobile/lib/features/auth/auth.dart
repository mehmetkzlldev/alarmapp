/// Public surface of the auth feature.
///
/// Other features should import this barrel rather than reaching into the
/// feature's internal directory structure.
library;

// Domain
export 'domain/entities/auth_session_entity.dart';
export 'domain/entities/auth_tokens_entity.dart';
export 'domain/entities/user_entity.dart';
export 'domain/repositories/auth_repository.dart';

// Presentation
export 'presentation/providers/auth_provider.dart';
export 'presentation/providers/auth_providers.dart';
export 'presentation/providers/auth_state.dart';
export 'presentation/screens/login_screen.dart';
export 'presentation/screens/register_screen.dart';
