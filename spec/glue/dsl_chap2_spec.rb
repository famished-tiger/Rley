# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework

# Load the class under test
require_relative '../../lib/mini_kraken/glue/dsl'


module MiniKraken
  module Glue
    describe 'DSL (Chap 2)' do
      include DSL

      context 'Chapter 2 examples:' do
        # ((:a) (:b) (:c))
        let(:abc) { cons(cons(:a), cons(cons(:b), cons(cons(:c)))) }

        # '(:a :c :o :r :n)
        let(:acorn) { cons(:a, cons(:c, cons(:o, cons(:r, cons(:n))))) }

        # '(:c :o :r :n)
        let(:corn) { cons(:c, cons(:o, cons(:r, cons(:n)))) }

        # '(:grape :raisin :pear)'
        let(:fruits) { cons(:grape, cons(:raisin, cons(:pear))) }

        let(:uuid_pattern) do
          /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
        end

        it 'accepts caro definition inspired from frame 2:6' do
          # Reasoned S2, frame 2:6
          # (defrel (caro p a)
          #   (fresh (d)
          #   (== (cons a d) p)))

          # As 'p' has a special meaning in Ruby, the argument has been renamed to 'r'
          caro_rel = defrel('caro', %w[r a], fresh('d', unify(cons(a, d), r)))

          # Check side-effect from DSL
          expect(instance_variable_get(:@defrels)['caro']).to eq(caro_rel)

          # Check results of defrel
          expect(caro_rel).to be_kind_of(Rela::DefRelation)
          expect(caro_rel.name).to eq('caro')
          expect(caro_rel.arity).to eq(2)
          expect(caro_rel.formals[0]).to match(/^r_/)
          expect(caro_rel.formals[0]).to match(uuid_pattern)
          expect(caro_rel.formals[1]).to match(/^a_/)
          expect(caro_rel.formals[1]).to match(uuid_pattern)
          g_template = caro_rel.expression

          # Checking the 'fresh' part
          expect(g_template).to be_kind_of(Core::Goal)
          expect(g_template.relation).to be_kind_of(Rela::Fresh)
          expect(g_template.actuals[0]).to eq('d')
          fresh_2nd_actual = g_template.actuals[1]

          # Checking the (== (cons a d) r) sub-expression
          expect(fresh_2nd_actual).to be_kind_of(Core::Goal)
          expect(fresh_2nd_actual.relation.name).to eq('unify')
          expect(fresh_2nd_actual.actuals[0]).to be_kind_of(Composite::ConsCell)
          expect(fresh_2nd_actual.actuals[0].to_s).to match(/^\(a_[-0-9a-f]+ \. d\)$/)
          expect(fresh_2nd_actual.actuals[1]).to be_kind_of(Core::LogVarRef)
          expect(fresh_2nd_actual.actuals[1].name).to match(/^r_[-0-9a-f]+$/)
        end

        # In Scheme:
        # (defrel (caro p a)
        #   (fresh (d)
        #   (== p (cons a d))))
        # In Ruby, `p`is a standard Kernel method => replace it by `r`
        def defrel_caro
          defrel('caro', %w[r a], fresh('d', unify(r, cons(a, d))))
        end

        it 'passes frame 2:3' do
          defrel_caro

          # (run* q
          #   (caro '(a c o r n) q)) ;; => (a)
          result = run_star('q', caro(acorn, q))
          expect(result.car).to eq(:a)
        end

        it 'passes frame 2:4' do
          defrel_caro

          # (run* q
          #   (caro '(a c o r n) 'a)) ;; => (_0)
          result = run_star('q', caro(acorn, :a))
          expect(result.car).to eq(:_0)
        end

        # IT FAILS
        it 'passes frame 2:5' do
          defrel_caro

          # (run* r
          #   (fresh (x y)
          #     (caro '(,r ,y) x)
          #     (== 'pear x)));; r => (pear)
          result = run_star('r', fresh(%w[x y],
            [caro(cons(r, cons(y)), x),
              unify(:pear, x)]))
          expect(result.car).to eq(:pear)
        end

        it 'passes frame 2:8' do
          defrel_caro

          # (run* r
          #   (fresh (x y)
          #     (caro '(grape raisin pear) x)
          #     (caro '((a) (b) (c)) y)
          #     (== (cons x y) r))) ;; r => ((grape a))

          result = run_star('r', fresh(%w[x y],
            [caro(fruits, x),
              caro(abc, y),
              unify(cons(x, y), r)]))
          expect(result.car).to eq(cons(:grape, cons(:a)))
        end

        it 'accepts cdro definition inspired from frame 2:13' do
          # Reasoned S2, frame 2:13
          # (defrel (cdro p d)
          #   (fresh (a)
          #   (== (cons a d) p)))

          # As 'p' has a special meaning in Ruby, the argument has been remaned to 'r'
          cdro_rel = defrel('cdro', %w[r d], fresh('a', unify(cons(a, d), r)))

          expect(cdro_rel).to be_kind_of(Rela::DefRelation)
          expect(cdro_rel.name).to eq('cdro')
          expect(cdro_rel.arity).to eq(2)
          expect(cdro_rel.formals[0]).to match(/^r_[-0-9a-f]+$/)
          expect(cdro_rel.formals[1]).to match(/^d_[-0-9a-f]+$/)
          g_template = cdro_rel.expression
          expect(g_template.relation).to be_kind_of(Rela::Fresh)
          expect(g_template.actuals).to include('a')
        end

        # In Scheme:
        # (defrel (cdro p d)
        #   (fresh (a)
        #   (== p (cons a d))))
        # In Ruby, `p`is a standard Kernel method => replace it by `r`
        def defrel_cdro
          defrel('cdro', %w[r d], fresh('a', unify(r, cons(a, d))))
        end

        it 'passes unnesting process in frame 2:12' do
          defrel_caro
          defrel_cdro

          # (run* r
          #   (fresh (v)
          #     (cdro '(acorn) v)
          #     (fresh (w)
          #       (cdro v w)
          #       (caro w r))) ;; r => (o)

          result = run_star('r', fresh('v',
            [cdro(acorn, v),
              fresh('w',
                [cdro(v, w),
                  caro(w, r)])]))
          expect(result.car).to eq(:o)
        end

        it 'passes frame 2:15' do
          defrel_caro
          defrel_cdro

          # (run* r
          #   (fresh (x y)
          #     (cdro '(grape raisin pear) x)
          #     (caro '((a) (b) (c)) y)
          #     (== (cons x y) r))) ;; r => (((raisin pear) a))

          result = run_star('r', fresh(%w[x y],
            [cdro(fruits, x),
              caro(abc, y),
              unify(cons(x, y), r)]))
          expect(result.to_s).to eq('(((:raisin :pear) :a))')
        end

        it 'passes frame 2:16' do
          defrel_cdro

          # (run* q
          #   (cdro '(a c o r n) '(c o r n))) ;; => (_0)
          result = run_star('r', cdro(acorn, corn))
          expect(result.car).to eq(:_0)
        end

        it 'passes frame 2:17' do
          defrel_cdro

          # (run* x
          #   (cdro '(c o r n) '(,x r n))) ;; => (o)
          result = run_star('x', cdro(corn, cons(x, cons(:r, cons(:n)))))
          expect(result.car).to eq(:o)
        end

        it 'passes frame 2:18' do
          defrel_caro
          defrel_cdro

          # (run* l
          #   (fresh (x)
          #     (cdro l '(c o r n))
          #     (caro l x)
          #     (== 'a x))) ;; l => ('(a c o r n))

          result = run_star('l', fresh('x',
            [cdro(l, corn), # WRONG l => a c o r n (side effect from other tests)
              caro(l, x),
              unify(:a, x)]))
          expect(result.to_s).to eq('((:a :c :o :r :n))')
        end
      end # context
    end # describe
  end # module
end # module
