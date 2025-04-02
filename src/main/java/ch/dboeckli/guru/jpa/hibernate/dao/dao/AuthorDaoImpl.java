package ch.dboeckli.guru.jpa.hibernate.dao.dao;

import ch.dboeckli.guru.jpa.hibernate.dao.domain.Author;
import ch.dboeckli.guru.jpa.hibernate.dao.repository.AuthorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@RequiredArgsConstructor
public class AuthorDaoImpl implements AuthorDao {

    private final AuthorRepository authorRepository;

    @Override
    public Author getById(Long id) {
        return authorRepository.getReferenceById(id);
    }

    @Override
    public Author findAuthorByName(String firstName, String lastName) {
        // TODO: NOT IMPLEMENTED YET
        return null;
    }

    @Override
    public Author saveNewAuthor(Author author) {
        return authorRepository.save(author);
    }

    @Override
    @Transactional
    public Author updateAuthor(Author author) {
        Author foundAuthor = authorRepository.getReferenceById(author.getId());
        foundAuthor.setFirstName(author.getFirstName());
        foundAuthor.setLastName(author.getLastName());
        return authorRepository.save(foundAuthor);
    }

    @Override
    public void deleteAuthorById(Long id) {
        authorRepository.deleteById(id);
    }
}
