"""changing post db

Revision ID: b217864db0fc
Revises: 362903955a4f
Create Date: 2020-05-15 17:23:49.868943

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'b217864db0fc'
down_revision = '362903955a4f'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    #op.add_column('post', sa.Column('title', sa.String(length=140), nullable=True))
    #op.add_column('post', sa.Column('url2', sa.String(length=140), nullable=True))
    with op.batch_alter_table('post') as batch_op:
    	batch_op.drop_column('body')
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.add_column('post', sa.Column('body', sa.VARCHAR(length=140), nullable=True))
    op.drop_column('post', 'url2')
    op.drop_column('post', 'title')
    # ### end Alembic commands ###
